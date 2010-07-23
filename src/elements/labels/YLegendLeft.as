package elements.labels {
	
	public class YLegendLeft extends YLegendBase {
		
		public function YLegendLeft( json:Object ) {
			super( json, 'y' );
		}
		
		public override function resize(pWidth:Number,pHeight:Number):void {
			if ( this.numChildren == 0 )
				return;
			
			this.y = (pHeight/2)+(this.getChildAt(0).height/2);
			this.x = 0;
		}
	}
}