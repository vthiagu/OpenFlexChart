package elements.labels {
	public class YLegendRight extends YLegendBase {
		
		public function YLegendRight( json:Object ) {
			super( json, 'y2' );
		}
		
		public override function resize(pWidth:Number,pHeight:Number):void {
			if ( this.numChildren == 0 )
				return;
			
			this.y = (pHeight/2)+(this.getChildAt(0).height/2);
			this.x = pWidth-this.getChildAt(0).width;
		}
	}
}