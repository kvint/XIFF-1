/*
 * Copyright (C) 2003-2009 Igniterealtime Community Contributors
 *
 *     Daniel Henninger
 *     Derrick Grigg <dgrigg@rogers.com>
 *     Juga Paazmaya <olavic@gmail.com>
 *     Nick Velloff <nick.velloff@gmail.com>
 *     Sean Treadway <seant@oncotype.dk>
 *     Sean Voisen <sean@voisen.org>
 *
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.igniterealtime.xiff.core
{
	import flash.events.*;
	import flash.net.*;
	import flash.utils.ByteArray;
	import flash.utils.Timer;

	import org.igniterealtime.xiff.core.*;
	import org.igniterealtime.xiff.data.*;
	import org.igniterealtime.xiff.events.*;

	/**
	 * Bidirectional-streams Over Synchronous HTTP (BOSH)
	 * @see http://xmpp.org/extensions/xep-0124.html
	 * @see http://xmpp.org/extensions/xep-0206.html
	 */
	public class XMPPBOSHConnection extends XMPPConnection
	{
		/**
		 * @default 1.6
		 */
		public static const BOSH_VERSION:String = "1.6";

		/**
		 * The default port as per XMPP specification.
		 * @default 7070
		 */
		public static const HTTP_PORT:uint = 7070;

		/**
		 * The default secure port as per XMPP specification.
		 * @default 7443
		 */
		public static const HTTPS_PORT:uint = 7443;

		/**
		 * Keys should match URLRequestMethod constants.
		 * @see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/net/URLRequestMethod.html
		 */
		private static const headers:Object = {
			"POST": [],
			"GET": [ 'Cache-Control',
					 'no-store',
					 'Cache-Control',
					 'no-cache',
					 'Pragma', 'no-cache' ]
		};

		private var _boshPath:String = "http-bind/";

		/**
		 * This attribute specifies the maximum number of requests the connection
		 * manager is allowed to keep waiting at any one time during the session.
		 * If the client is not able to use HTTP Pipelining then this SHOULD be set to "1".
		 */
		private var _hold:uint = 1;

		private var _maxConcurrentRequests:uint = 2;

		private var _secure:Boolean;

		/**
		 * This attribute specifies the longest time (in seconds) that the connection
		 * manager is allowed to wait before responding to any request during the session.
		 * This enables the client to limit the delay before it discovers any network
		 * failure, and to prevent its HTTP/TCP connection from expiring due to inactivity.
		 */
		private var _wait:uint = 20;

		/**
		 * Polling interval, in seconds
		 */
		private var boshPollingInterval:uint = 10;

		/**
		 * Inactivity time, in seconds
		 */
		private var inactivity:uint;

		private var isDisconnecting:Boolean = false;

		private var lastPollTime:Date = null;

		/**
		 * Maximum pausing time, in seconds
		 */
		private var maxPause:uint;

		private var pauseEnabled:Boolean = false;

		private var pollingEnabled:Boolean = false;

		private var requestCount:int = 0;

		private var requestQueue:Array = [];

		private var responseQueue:Array = [];

		private var responseTimer:Timer;

		/**
		 * Optional, positive integer.
		 */
		private var rid:uint;

		private var sid:String;

		private var streamRestarted:Boolean;

		/**
		 *
		 * @param	secure	Determines which port is used
		 */
		public function XMPPBOSHConnection( secure:Boolean = false ):void
		{
			super();
			this.secure = secure;
			responseTimer = new Timer( 0.0, 1 );
			responseTimer.addEventListener( TimerEvent.TIMER_COMPLETE, processResponse );
		}

		override public function connect( streamType:uint = 0 ):Boolean
		{
			var result:XML = <body/>;
			result.@[ "xml:lang" ] = XMPPStanza.XML_LANG;
			result.setNamespace( "http://jabber.org/protocol/httpbind" );
			result.@[ "xmlns:xmpp" ] = "urn:xmpp:xbosh";
			result.@[ "xmpp:version" ] = XMPPStanza.CLIENT_VERSION;
			result.@hold = hold;
			result.@rid = nextRID;
			result.@secure = secure;
			result.@wait = wait;
			result.@ver = BOSH_VERSION;
			result.@to = domain;

			sendRequests( result );

			return true;
		}

		override public function disconnect():void
		{
			if ( active )
			{
				var data:XML = createRequest();
				data.@type = "terminate";
				sendRequests( data );
				active = false;
				loggedIn = false;
				dispatchEvent( new DisconnectionEvent() );
			}
		}

		/**
		 * @return	true if pause request is sent
		 */
		public function pauseSession( seconds:uint ):Boolean
		{
			trace( "Pausing session for {0} seconds", seconds );

			if ( !pauseEnabled || seconds > maxPause || seconds <= boshPollingInterval )
			{
				return false;
			}

			pollingEnabled = false;

			var data:XML = createRequest();
			data.@pause = seconds;
			sendRequests( data );

			var pauseTimer:Timer = new Timer( ( seconds * 1000 ) - 2000, 1 );
			pauseTimer.addEventListener( TimerEvent.TIMER, handlePauseTimeout );
			pauseTimer.start();

			return true;
		}

		/**
		 *
		 * @param	responseBody
		 */
		public function processConnectionResponse( response:XML ):void
		{
			dispatchEvent( new ConnectionSuccessEvent() );

			sid = response.@sid;
			wait = response.@wait;

			if ( response.@polling )
			{
				boshPollingInterval = response.@polling;
			}
			if ( response.@inactivity )
			{
				inactivity = response.@inactivity;
			}
			if ( response.@maxpause )
			{
				maxPause = response.@maxpause;
				pauseEnabled = true;
			}
			if ( response.@requests )
			{
				maxConcurrentRequests = response.@requests;
			}

			trace( "Polling interval: {0}", boshPollingInterval );
			trace( "Inactivity timeout: {0}", inactivity );
			trace( "Max requests: {0}", maxConcurrentRequests );
			trace( "Max pause: {0}", maxPause );

			active = true;

			addEventListener( LoginEvent.LOGIN, handleLogin );
		}

		//do nothing, we use polling instead
		override public function sendKeepAlive():void
		{
		}

		override protected function restartStream():void
		{
			var data:XML = createRequest();
			data.@[ "xmpp:restart" ] = "true";
			data.@[ "xmlns:xmpp" ] = "urn:xmpp:xbosh";
			data.@[ "xml:lang" ] = "en";
			data.@to = domain;
			sendRequests( data );
			streamRestarted = true;
		}

		override protected function sendXML( someData:* ):void
		{
			// XML
			sendQueuedRequests( someData );
		}

		/**
		 *
		 * @param	bodyContent
		 * @return
		 */
		private function createRequest( bodyContent:Array = null ):XML
		{
			var req:XML = <body/>;
			req.setNamespace( "http://jabber.org/protocol/httpbind" );
			req.@rid = nextRID;
			req.@sid = sid;

			if ( bodyContent )
			{
				for each ( var content:XML in bodyContent )
				{
					req.appendChild( content );
				}
			}

			return req;
		}

		/**
		 *
		 * @param	event
		 */
		private function handleLogin( event:LoginEvent ):void
		{
			pollingEnabled = true;
			pollServer();
		}

		/**
		 *
		 * @param	event
		 */
		private function handlePauseTimeout( event:TimerEvent ):void
		{
			pollingEnabled = true;
			pollServer();
		}

		private function onRequestComplete( event:Event ):void
		{
			var loader:URLLoader = event.target as URLLoader;

			requestCount--;
			var byteData:ByteArray = loader.data as ByteArray;
			var data:String = byteData.readUTFBytes( byteData.length );
			var rawXML:String = _incompleteRawXML + data;

			var xmlData:XML = new XML();
			xmlData.ignoreWhiteSpace = ignoreWhiteSpace;
			var isComplete:Boolean = true;

			//error handling to catch incomplete xml strings that have
			//been truncated by the socket
			try
			{
				xmlData = new XML( rawXML );
				_incompleteRawXML = "";
			}
			catch ( error:Error )
			{
				//concatenate the raw xml to the previous xml
				isComplete = false;
				_incompleteRawXML += data;
			}

			var incomingEvent:IncomingDataEvent = new IncomingDataEvent();
			incomingEvent.data = byteData;
			dispatchEvent( incomingEvent );

			var bodyNode:XML = xmlData[ 0 ];

			if ( streamRestarted && bodyNode.children().length() == 0 )
			{
				streamRestarted = false;
				bindConnection();
			}

			if ( bodyNode.@type.toString() == "terminate" )
			{
				dispatchError( "BOSH Error", bodyNode.@condition.toString(), "",
							   -1 );
				active = false;
			}

			if ( bodyNode.@sid.length() > 0 && !loggedIn )
			{
				processConnectionResponse( bodyNode );

				var featuresFound:Boolean = false;
				var children:XMLList = bodyNode.children();
				for each ( var child:XML in children )
				{
					if ( child.name() == "stream:features" )
					{
						featuresFound = true;
					}
				}
				if ( !featuresFound )
				{
					pollingEnabled = true;
					pollServer();
				}
			}

			var items:XMLList = bodyNode.children();
			for each ( var item:XML in items )
			{
				responseQueue.push( item );
			}

			resetResponseProcessor();

			//if we have no outstanding requests, then we're free to send a poll at the next opportunity
			if ( requestCount == 0 && !sendQueuedRequests() )
			{
				pollServer();
			}
		}

		/**
		 *
		 */
		private function pollServer():void
		{
			/*
			 * We shouldn't poll if the connection is dead, if we had requests
			 * to send instead, or if there's already one in progress
			 */
			if ( !isActive() || !pollingEnabled || sendQueuedRequests() || requestCount >
				0 )
			{
				return;
			}

			/*
			 * this should be safe since sendRequests checks to be sure it's not
			 * over the concurrent requests limit, and we just ensured that the queue
			 * is empty by calling sendQueuedRequests()
			 */
			sendRequests( null, true );
		}

		/**
		 *
		 * @param	event
		 */
		private function processResponse( event:TimerEvent = null ):void
		{
			// Read the data and send it to the appropriate parser
			var currentNode:XML = responseQueue.shift();
			var nodeName:String = currentNode.nodeName.toLowerCase();

			switch ( nodeName )
			{
				case "stream:features":
					handleStreamFeatures( currentNode );
					streamRestarted = false; //avoid triggering the old server workaround
					break;

				case "stream:error":
					handleStreamError( currentNode );
					break;

				case "iq":
					handleIQ( currentNode );
					break;

				case "message":
					handleMessage( currentNode );
					break;

				case "presence":
					handlePresence( currentNode );
					break;

				case "success":
					handleAuthentication( currentNode );
					break;

				case "failure":
					handleAuthentication( currentNode );
					break;
				default:
					dispatchError( "undefined-condition", "Unknown Error", "modify",
								   500 );
					break;
			}

			resetResponseProcessor();
		}

		/**
		 *
		 */
		private function resetResponseProcessor():void
		{
			if ( responseQueue.length > 0 )
			{
				responseTimer.reset();
				responseTimer.start();
			}
		}

		/**
		 *
		 * @param	body
		 * @return
		 */
		private function sendQueuedRequests( body:XML = null ):Boolean
		{
			if ( body )
			{
				requestQueue.push( body );
			}
			else if ( requestQueue.length == 0 )
			{
				return false;
			}

			return sendRequests();
		}

		/**
		 * Returns true if any requests were sent
		 * @param	data
		 * @param	isPoll
		 * @return
		 */
		private function sendRequests( data:XML = null, isPoll:Boolean = false ):Boolean
		{
			if ( requestCount >= maxConcurrentRequests )
			{
				return false;
			}

			requestCount++;

			if ( !data )
			{
				if ( isPoll )
				{
					data = createRequest();
				}
				else
				{
					var requests:Array = [];
					var len:uint = Math.min( 10, requestQueue.length ); // ten or less
					for ( var i:uint = 0; i < len; ++i )
					{
						requests.push( requestQueue.shift() );
					}
					data = createRequest( requests );
				}
			}

			var byteData:ByteArray = new ByteArray();
			byteData.writeUTFBytes( data.toString() );

			var req:URLRequest = new URLRequest( httpServer );
			req.method = URLRequestMethod.POST;
			req.contentType = "text/xml";
			req.requestHeaders = headers[ req.method ];
			req.data = byteData;

			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener( Event.COMPLETE, onRequestComplete );
			loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onSecurityError );
			loader.addEventListener( IOErrorEvent.IO_ERROR, onIOError );
			loader.load( req );

			var event:OutgoingDataEvent = new OutgoingDataEvent();
			event.data = byteData;
			dispatchEvent( event );

			if ( isPoll )
			{
				lastPollTime = new Date();
				trace( "Polling" );
			}

			return true;
		}

		/**
		 *
		 */
		public function get boshPath():String
		{
			return _boshPath;
		}

		public function set boshPath( value:String ):void
		{
			_boshPath = value;
		}

		/**
		 *
		 */
		private function get nextRID():uint
		{
			if ( !rid )
			{
				rid = Math.floor( Math.random() * 1000000 + 10 );
			}
			return ++rid;
		}

		/**
		 *
		 */
		public function get wait():uint
		{
			return _wait;
		}

		public function set wait( value:uint ):void
		{
			_wait = value;
		}

		/**
		 * The usage of the secure or less secure port.
		 */
		public function get secure():Boolean
		{
			return _secure;
		}

		public function set secure( value:Boolean ):void
		{
			_secure = value;
			port = _secure ? HTTPS_PORT : HTTP_PORT;
		}

		/**
		 *
		 */
		public function get hold():uint
		{
			return _hold;
		}

		public function set hold( value:uint ):void
		{
			_hold = value;
		}

		/**
		 * Server URI
		 */
		public function get httpServer():String
		{
			return ( secure ? "https" : "http" ) + "://" + server + ":" + port +
				"/" + boshPath;
		}

		/**
		 *
		 */
		public function get maxConcurrentRequests():uint
		{
			return _maxConcurrentRequests;
		}

		public function set maxConcurrentRequests( value:uint ):void
		{
			_maxConcurrentRequests = value;
		}
	}
}
