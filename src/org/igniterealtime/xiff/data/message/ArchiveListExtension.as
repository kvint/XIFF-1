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
	import org.igniterealtime.xiff.data.IExtension;
	import org.igniterealtime.xiff.core.UnescapedJID;
	import org.igniterealtime.xiff.util.DateTimeParser;
	
	/**
	 * XEP-0136: Message Archiving
	 *
	 * @see http://xmpp.org/extensions/xep-0136.html
	 */
	public class ArchiveListExtension extends ArchiveExtension implements IExtension
	{
		public static const ELEMENT_NAME:String = "list";
		
		/**
		 *
		 * @param	parent
		 */
		public function ArchiveListExtension( parent:XML = null )
		{
			super(parent);
		}
		
		public function getElementName():String
		{
			return ArchiveListExtension.ELEMENT_NAME;
        }
		public function get chats():Vector.<ArchiveChatCollection>
		{
			var list:Vector.<ArchiveChatCollection> = new Vector.<ArchiveChatCollection>();
			for each(var child:XML in xml.children().(localName() == ArchiveChatCollection.ELEMENT_NAME))
			{
				var item:ArchiveChatCollection = new ArchiveChatCollection();
				item.xml = child;
				list.push(item);
			}
			return list;
		}

		public function set chats(value:Vector.<ArchiveChatCollection>):void
		{
			removeFields(ArchiveChatCollection.ELEMENT_NAME);

			if (value != null)
			{
				var len:uint = value.length;
				for (var i:uint = 0; i < len; ++i)
				{
					var item:ArchiveChatCollection = value[i];
					xml.appendChild(item.xml);
				}
			}
		}
		
		/**
		 *
		 */
		public function get withJid():UnescapedJID
		{
			var value:String = getAttribute("with");
			if ( value != null )
			{
				return new UnescapedJID(value);
			}
			return null;
		}
		public function set withJid( value:UnescapedJID ):void
		{
			if ( value == null )
			{
				setAttribute("with", null);
			}
			else
			{
				setAttribute("with", value.toString());
			}
		}
		
		/**
		 *
		 */
		public function get start():Date
		{
			return DateTimeParser.string2dateTime(getAttribute("start"));
		}
		public function set start( value:Date ):void
		{
			if ( value == null )
			{
				setAttribute("start", null);
			}
			else
			{
				setAttribute("start", DateTimeParser.dateTime2string(value));
			}
		}
		
		/**
		 *
		 */
		public function get end():Date
		{
			return DateTimeParser.string2dateTime(getAttribute("end"));
		}
		public function set end( value:Date ):void
		{
			if ( value == null )
			{
				setAttribute("end", null);
			}
			else
			{
				setAttribute("end", DateTimeParser.dateTime2string(value));
			}
		}
	}
}
