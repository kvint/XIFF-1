/**
 * Created by AlexanderSla on 28.11.2014.
 */
package org.igniterealtime.xiff.data.id
{
	public class RandomGenerator implements IIDGenerator
	{

		private static const HEX:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890";
		private var _prefix:String;
		private var _size:uint;

		public function RandomGenerator(size:uint = 6):void
		{
			_size = size;
		}

		public function get prefix():String
		{
			return _prefix;
		}

		public function set prefix(value:String):void
		{
			_prefix = value;
		}

		public function generateID():String
		{
			var result:String = "";
			for (var i:int = 0; i < _size; i++)
			{
				var ri:Number = Math.floor(Math.random() * (HEX.length - 1));
				result += HEX.charAt(ri);
			}
			if (_prefix != null)
			{
				id = _prefix + result;
			} else
			{
				id = result;
			}
			return id;
		}

		var id:String;

	}
}
