/*
 * Copyright (C) 2003-2012 Igniterealtime Community Contributors
 *
 *     Daniel Henninger
 *     Derrick Grigg <dgrigg@rogers.com>
 *     Juga Paazmaya <olavic@gmail.com>
 *     Nick Velloff <nick.velloff@gmail.com>
 *     Sean Treadway <seant@oncotype.dk>
 *     Sean Voisen <sean@voisen.org>
 *     Mark Walters <mark@yourpalmark.com>
 *     Michael McCarthy <mikeycmccarthy@gmail.com>
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
package org.igniterealtime.xiff.data.message
{
	import org.igniterealtime.xiff.core.UnescapedJID;
	import org.igniterealtime.xiff.data.XMLStanza;
	import org.igniterealtime.xiff.util.DateTimeParser;

	/**
	 * XEP-0136: Message Archiving
	 *
	 * @see http://xmpp.org/extensions/xep-0136.html#collections
	 */
	public class ArchiveChatCollection extends XMLStanza
	{
		public static const ELEMENT_NAME:String = "chat";
		public static const START:String = "start";
		public static const SUBJECT:String = "subject";
		public static const THREAD:String = "thread";
		public static const WITH:String = "with";
		/**
		 *
		 */
		public function ArchiveChatCollection()
		{
			
		}
		public function get start():Date
		{
			return DateTimeParser.string2dateTime(getAttribute(START));
		}
		public function set start( value:Date ):void
		{
			if ( value == null )
			{
				setAttribute(START, null);
			}
			else
			{
				setAttribute(START, DateTimeParser.dateTime2string(value));
			}
		}

		public function get thread():String
		{
			return getAttribute(THREAD);
		}

		public function set thread(value:String):void
		{
			setAttribute(THREAD, value);
		}

		public function get withJID():UnescapedJID
		{
			var value:String = getAttribute(WITH);
			if (value != null)
			{
				return new UnescapedJID(value);
			}
			return null;
		}

		public function set withJID(value:UnescapedJID):void
		{
			if ( value == null )
			{
				setAttribute(WITH, null);
			}
			else
			{
				setAttribute(WITH, value.toString());
			}
		}

		public function getNS():String
		{
			return ArchiveExtension.NS;
		}

		public function getElementName():String
		{
			return ELEMENT_NAME;
		}
	}
}
