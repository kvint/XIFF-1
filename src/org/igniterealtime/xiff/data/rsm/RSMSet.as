/**
 * Created by AlexanderSla on 06.11.2014.
 */
package org.igniterealtime.xiff.data.rsm
{
	import org.igniterealtime.xiff.data.Extension;
	import org.igniterealtime.xiff.data.IExtension;

	/**
	 * TODO: add specifications
	 */

	public class RSMSet extends Extension implements IExtension
	{

		public static const NS:String = "http://jabber.org/protocol/rsm";
		public static const ELEMENT_NAME:String = "set";

		private static const FIRST:String = "first";
		private static const MAX:String = "max";
		private static const LAST:String = "last";
		private static const INDEX:String = "index";
		private static const COUNT:String = "count";
		private static const BEFORE:String = "before";
		private static const AFTER:String = "after";

		public function get max():int
		{
			return int(getField(MAX));
		}

		public function set max(value:int):void
		{
			setField(MAX, String(value));
		}

		public function get last():String
		{
			return getField(LAST);
		}

		public function set last(value:String):void
		{
			setField(LAST, value);
		}

		public function get index():int
		{
			return int(getField(INDEX));
		}

		public function set index(value:int):void
		{
			setField(INDEX, String(value));
		}

		public function get count():int
		{
			return int(getField(COUNT));
		}

		public function set count(value:int):void
		{
			setField(COUNT, String(value));
		}

		public function get before():String
		{
			return getField(BEFORE);
		}

		public function set before(value:String):void
		{
			setField(BEFORE, value);
		}

		public function get after():String
		{
			return getField(AFTER);
		}

		public function set after(value:String):void
		{
			setField(AFTER, value);
		}

		public function get first():String
		{
			return getField(FIRST);
		}

		public function set first(value:String):void
		{
			setField(FIRST, value);
		}

		public function get firstIndex():int
		{
			return int(getChildAttribute(FIRST, "index"));
		}

		public function set firstIndex(value:int):void
		{
			setChildAttribute(FIRST, "index", value.toString());
		}

		public function getNS():String
		{
			return NS;
		}

		public function getElementName():String
		{
			return ELEMENT_NAME;
		}
	}
}