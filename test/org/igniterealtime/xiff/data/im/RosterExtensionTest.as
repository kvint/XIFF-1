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
package org.igniterealtime.xiff.data.im
{
	
	import org.flexunit.asserts.*;
	
	public class RosterExtensionTest
	{
		
		
		
		[Test( description="XML element name and namespace checking" )]
		public function testElement():void
		{
			var nameSpace:String = "jabber:iq:roster";
			var elementName:String = "query";
			
			var ext:RosterExtension = new RosterExtension();
			var node:XML = ext.xml;
			
			assertEquals( nameSpace, node.namespace().uri );
			assertEquals( elementName, node.localName() );
		}
		
		[Test( description="XML parse - getAllItems length" )]
		public function testParseGetAllItemsLength():void
		{
			var incoming:XML = <query xmlns='jabber:iq:roster' ver='ver7'>
				 <item jid='nurse@example.com'/>
				 <item jid='romeo@example.net'/>
			   </query>;
			var testValue:uint = 2;
			
			var ext:RosterExtension = new RosterExtension();
			ext.xml = incoming;
			
			assertEquals( testValue, ext.items.length );
		}
	}
}
