
package  {
	import charts.series.Element;
	import charts.Factory;
	import charts.ObjectCollection;
	import elements.menu.Menu;
	import charts.series.has_tooltip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	// for image upload:
	import flash.events.ProgressEvent;
	import flash.net.URLVariables;
	
	import flash.display.Sprite;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import string.Utils;
	import global.Global;
	import com.serialization.json.JSON;
	import flash.external.ExternalInterface;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.events.IOErrorEvent;
	import flash.events.ContextMenuEvent;
	import flash.system.System;
	
	import flash.display.LoaderInfo;

	// export the chart as an image
	import com.adobe.images.PNGEncoder;
	import com.adobe.images.JPGEncoder;
	import mx.utils.Base64Encoder;
	// import com.dynamicflash.util.Base64;
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLLoaderDataFormat;
	import elements.axis.XAxis;
	import elements.axis.XAxisLabels;
	import elements.axis.YAxisBase;
	import elements.axis.YAxisLeft;
	import elements.axis.YAxisRight;
	import elements.axis.RadarAxis;
	import elements.Background;
	import elements.labels.XLegend;
	import elements.labels.Title;
	import elements.labels.Keys;
	import elements.labels.YLegendBase;
	import elements.labels.YLegendLeft;
	import elements.labels.YLegendRight;
	import mx.core.UIComponent;
	
	public class Chart extends UIComponent {
		
		public  var VERSION:String = "2 Kvasir";
		private var title:Title = null;
		//private var x_labels:XAxisLabels;
		private var x_axis:XAxis;
		private var radar_axis:RadarAxis;
		private var x_legend:XLegend;
		private var y_axis:YAxisBase;
		private var y_axis_right:YAxisBase;
		private var y_legend:YLegendBase;
		private var y_legend_2:YLegendBase;
		private var keys:Keys;
		private var obs:ObjectCollection;
		public var tool_tip_wrapper:String;
		private var sc:ScreenCoords;
		private var tooltip:Tooltip;
		private var background:Background;
		private var menu:Menu;
		private var ok:Boolean;
		private var URL:String;		// ugh, vile. The IOError doesn't report the URL
		private var _chartData:String;
		private var _width:Number;
		private var _height:Number;
		private var _loadingString:String = "Loading...";
	
		public function Chart() {
			super();
			this._width=700;
			this._height=500;
			this.build_right_click_menu();
			this.ok = false;
			this.addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}
		
		public function getVersion():String {return VERSION;}
		
		private function addedToStage(event:Event):void{
			this.removeEventListener(Event.ADDED_TO_STAGE, addedToStage);
			var l:Loading = new Loading(this._loadingString,this._width,this._height);
			this.addChild( l );
			this.set_the_stage();
			if(this._chartData){
				this.parse_json(this._chartData );
			}
		}
		
		override public function set width(value:Number):void {
			this._width=value;
		}
		
		override public function set height(value:Number):void {
			this._height=value;
		}
		
		public function set loadingString(value:String):void {
			this._loadingString=value;
		}
		
		override public function get width():Number {
			return this._width;
		}
		
		override public function get height():Number {
			return this._height;
		}
		
		public function load():void {
			this.parse_json(this._chartData );
		}
		
		public function set chartData(value:String):void {
			this._chartData=value;
			this.parse_json(this._chartData );
		}
			
		private function onContextMenuHandler(event:ContextMenuEvent):void
		{
		}
		
		public function get_x_legend() : XLegend {
			return this.x_legend;
		}
		
		private function set_the_stage():void {

			// tell flash to align top left, and not to scale
			// anything (we do that in the code)
			this.stage.align = StageAlign.TOP_LEFT;
			//
			// ----- RESIZE ----
			//
			// noScale: now we can pick up resize events
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
            this.stage.addEventListener(Event.ACTIVATE, this.activateHandler);
            this.stage.addEventListener(Event.RESIZE, this.resizeHandler);
			this.stage.addEventListener(Event.MOUSE_LEAVE, this.mouseOut);
			this.addEventListener(MouseEvent.ROLL_OUT, this.mouseOut);
			this.addEventListener( MouseEvent.MOUSE_OVER, this.mouseMove );
		}
		
		
		private function mouseMove( event:Event ):void {
			// tr.ace( 'over ' + event.target );
			// tr.ace('move ' + Math.random().toString());
			// tr.ace( this.tooltip.get_tip_style() );
			
			if ( !this.tooltip )
				return;		// <- an error and the JSON was not loaded
				
			switch( this.tooltip.get_tip_style() ) {
				case Tooltip.CLOSEST:
					this.mouse_move_closest( event );
					break;
					
				case Tooltip.PROXIMITY:
					this.mouse_move_proximity( event as MouseEvent );
					break;
					
				case Tooltip.NORMAL:
					this.mouse_move_follow( event as MouseEvent );
					break;
					
			}
		}
		
		private function mouse_move_follow( event:MouseEvent ):void {

			// tr.ace( event.currentTarget );
			// tr.ace( event.target );
			
			if ( event.target is has_tooltip )
				this.tooltip.draw( event.target as has_tooltip );
			else
				this.tooltip.hide();
		}
		
		private function mouse_move_proximity( event:MouseEvent ):void {

			//tr.ace( event.currentTarget );
			//tr.ace( event.target );
			
			var elements:Array = this.obs.mouse_move_proximity( this.mouseX, this.mouseY );
			this.tooltip.closest( elements );
		}
		
		private function mouse_move_closest( event:Event ):void {
			
			var elements:Array = this.obs.closest_2( this.mouseX, this.mouseY );
			this.tooltip.closest( elements );
		}
		
		private function activateHandler(event:Event):void {
            tr.aces("activateHandler:", event);
			tr.aces("stage", this.stage);
        }

        private function resizeHandler(event:Event):void {
            // tr.ace("resizeHandler: " + event);
            this.resize();
        }
		
		//
		// pie charts are simpler to resize, they don't
		// have all the extras (X,Y axis, legends etc..)
		//
		private function resize_pie(): ScreenCoordsBase {
			
			// should this be here?
			this.addEventListener(MouseEvent.MOUSE_MOVE, this.mouseMove);
			
			this.background.resize(this._width,this._height);
			this.title.resize(this._width,this._height);
			
			// this object is used in the mouseMove method
			this.sc = new ScreenCoords(
				this.title.get_height(), 0, this._width, this._height,
				null, null, null, 0, 0, false );
			this.obs.resize( sc );
			
			return sc;
		}
		
		//
		//
		private function resize_radar(): ScreenCoordsBase {
			
			this.addEventListener(MouseEvent.MOUSE_MOVE, this.mouseMove);
			
			this.background.resize(this._width,this._height);
			this.title.resize(this._width,this._height);
			this.keys.resize( 0, this.title.get_height(),this._width,this._height );
				
			var top:Number = this.title.get_height() + this.keys.get_height();
			
			// this object is used in the mouseMove method
			var sc:ScreenCoordsRadar = new ScreenCoordsRadar(top, 0, this._width, this._height);
			
			sc.set_range( this.radar_axis.get_range() );
			// 0-4 = 5 spokes
			sc.set_angles( this.obs.get_max_x()-this.obs.get_min_x()+1 );
			
			// resize the axis first because they may
			// change the radius (to fit the labels on screen)
			this.radar_axis.resize( sc );
			this.obs.resize( sc );
			
			return sc;
		}
		
		private function resize():void {
			//
			// the chart is async, so we may get this
			// event before the chart has loaded, or has
			// partly loaded
			//
			if ( !this.ok )
				return;			// <-- something is wrong
		
			var sc:ScreenCoordsBase;
			
			if ( this.radar_axis != null )
				sc = this.resize_radar();
			else if ( this.obs.has_pie() )
				sc = this.resize_pie();
			else
				sc = this.resize_chart();
			
			if( this.menu )
				this.menu.resize(this._width,this._height);
			
				
			sc = null;
		}
			
		private function resize_chart(): ScreenCoordsBase {
			//
			// we want to show the tooltip closest to
			// items near the mouse, so hook into the
			// mouse move event:
			//
			this.addEventListener(MouseEvent.MOUSE_MOVE, this.mouseMove);
	
			// FlashConnect.trace("stageWidth: " + stage.stageWidth + " stageHeight: " + stage.stageHeight);
			this.background.resize(this._width,this._height);
			this.title.resize(this._width,this._height);
			
			var left:Number   = this.y_legend.get_width() /*+ this.y_labels.get_width()*/ + this.y_axis.get_width();
			
			this.keys.resize( left, this.title.get_height(),this._width,this._height);
				
			var top:Number = this.title.get_height() + this.keys.get_height();
			
			var bottom:Number = this._height;
			bottom -= (this.x_legend.get_height() + this.x_axis.get_height());
			
			var right:Number = this._width;
			right -= this.y_legend_2.get_width();
			//right -= this.y_labels_right.get_width();
			right -= this.y_axis_right.get_width();

			// this object is used in the mouseMove method
			this.sc = new ScreenCoords(
				top, left, right, bottom,
				this.y_axis.get_range(),
				this.y_axis_right.get_range(),
				this.x_axis.get_range(),
				this.x_axis.first_label_width(),
				this.x_axis.last_label_width(),
				false );

			this.sc.set_bar_groups(this.obs.groups);
				
			this.x_axis.resize( sc,
				// can we remove this:
				this._height-(this.x_legend.get_height()+this.x_axis.labels.get_height())	// <-- up from the bottom
				);
			this.y_axis.resize( this.y_legend.get_width(), sc );
			this.y_axis_right.resize( 0, sc );
			this.x_legend.resize( sc ,this._width,this._height);
			this.y_legend.resize(this._width,this._height);
			this.y_legend_2.resize(this._width,this._height);
			
			this.obs.resize( sc );
			
			
			// Test code:
			this.dispatchEvent(new Event("on-show"));
			
			
			return sc;
		}
		
		private function mouseOut(event:Event):void {
			
			if( this.tooltip != null )
				this.tooltip.hide();
			
			if( this.obs != null )
				this.obs.mouse_out();
        }
		
		//
		// JSON is loaded from an external URL
		//
		private function xmlLoaded(event:Event):void {
			var loader:URLLoader = URLLoader(event.target);
			this.parse_json( loader.data );
		}
		
		//
		// we have data! parse it and make the chart
		//
		private function parse_json( json_string:String ):void {
			
			// tr.ace(json_string);
			
			var ok:Boolean = false;
			
			try {
				var json:Object = JSON.deserialize( json_string );
				ok = true;
			}
			catch (e:Error) {
				// remove the 'loading data...' msg:
				this.removeChildAt(0);
				this.addChild( new JsonErrorMsg( json_string as String, e ) );
			}
			
			//
			// don't catch these errors:
			//
			if( ok )
			{
				// remove 'loading data...' msg:
				this.removeChildAt(0);
				this.build_chart( json );
				
				// force this to be garbage collected
				json = null;
			}
			
			json_string = '';
		}
		
		private function build_chart( json:Object ):void {
			
			tr.ace('----');
			tr.ace(JSON.serialize(json));
			tr.ace('----');
			
			if ( this.obs != null )
				this.die();
			
			// init singletons:
			NumberFormat.getInstance( json );
			NumberFormat.getInstanceY2( json );

			this.tooltip	= new Tooltip( json.tooltip )

			var g:Global = Global.getInstance();
			g.set_tooltip_string( this.tooltip.tip_text );
		
			//
			// these are common to both X Y charts and PIE charts:
			this.background	= new Background( json );
			this.title		= new Title( json.title );
			//
			this.addChild( this.background );
			//
			
			if ( JsonInspector.is_radar( json ) ) {
				
				this.obs = Factory.MakeChart( json );
				this.radar_axis = new RadarAxis( json.radar_axis );
				this.keys = new Keys( this.obs );
				
				this.addChild( this.radar_axis );
				this.addChild( this.keys );
				
			}
			else if ( !JsonInspector.has_pie_chart( json ) )
			{
				this.build_chart_background( json );
			}
			else
			{
				// this is a PIE chart
				this.obs = Factory.MakeChart( json );
				// PIE charts default to FOLLOW tooltips
				this.tooltip.set_tip_style( Tooltip.NORMAL );
			}

			// these are added in the Flash Z Axis order
			this.addChild( this.title );
			for each( var set:Sprite in this.obs.sets )
				this.addChild( set );
			this.addChild( this.tooltip );

			if (json['menu'] != null) {
				this.menu = new Menu('99', json['menu']);
				this.addChild(this.menu);
			}
			
			this.ok = true;
			this.resize();
			
			
		}
		
		//
		// PIE charts don't have this.
		// build grid, axis, legends and key
		//
		private function build_chart_background( json:Object ):void {
			//
			// This reads all the 'elements' of the chart
			// e.g. bars and lines, then creates them as sprites
			//
			this.obs			= Factory.MakeChart( json );
			//
			this.x_legend		= new XLegend( json.x_legend );			
			this.y_legend		= new YLegendLeft( json );
			this.y_legend_2		= new YLegendRight( json );
			this.x_axis			= new XAxis( json, this.obs.get_min_x(), this.obs.get_max_x() );
			this.y_axis			= new YAxisLeft();
			this.y_axis_right	= new YAxisRight();
			
			// access all our globals through this:
			var g:Global = Global.getInstance();
			// this is needed by all the elements tooltip
			g.x_labels = this.x_axis.labels;
			g.x_legend = this.x_legend;

			//
			// pick up X Axis labels for the tooltips
			// 
			this.obs.tooltip_replace_labels( this.x_axis.labels );
			//
			//
			//
			
			this.keys = new Keys( this.obs );
			
			this.addChild( this.x_legend );
			this.addChild( this.y_legend );
			this.addChild( this.y_legend_2 );
			this.addChild( this.y_axis );
			this.addChild( this.y_axis_right );
			this.addChild( this.x_axis );
			this.addChild( this.keys );
			
			// now these children have access to the stage,
			// tell them to init
			this.y_axis.init(json,this._height);
			this.y_axis_right.init(json,this._height);
		}
		
		/**
		 * Remove all our referenced objects
		 */
		private function die():void {
			this.obs.die();
			this.obs = null;
			
			if ( this.tooltip != null ) this.tooltip.die();
			
			if ( this.x_legend != null )	this.x_legend.die();
			if ( this.y_legend != null )	this.y_legend.die();
			if ( this.y_legend_2 != null )	this.y_legend_2.die();
			if ( this.y_axis != null )		this.y_axis.die();
			if ( this.y_axis_right != null ) this.y_axis_right.die();
			if ( this.x_axis != null )		this.x_axis.die();
			if ( this.keys != null )		this.keys.die();
			if ( this.title != null )		this.title.die();
			if ( this.radar_axis != null )	this.radar_axis.die();
			if ( this.background != null )	this.background.die();
			
			this.tooltip = null;
			this.x_legend = null;
			this.y_legend = null;
			this.y_legend_2 = null;
			this.y_axis = null;
			this.y_axis_right = null;
			this.x_axis = null;
			this.keys = null;
			this.title = null;
			this.radar_axis = null;
			this.background = null;
			
			while ( this.numChildren > 0 )
				this.removeChildAt(0);
		
			if ( this.hasEventListener(MouseEvent.MOUSE_MOVE))
				this.removeEventListener(MouseEvent.MOUSE_MOVE, this.mouseMove);
			
			// do not force a garbage collection, it is not supported:
			// http://stackoverflow.com/questions/192373/force-garbage-collection-in-as3
		
		}
		
		private function build_right_click_menu(): void {
		
			var cm:ContextMenu = new ContextMenu();
			cm.addEventListener(ContextMenuEvent.MENU_SELECT, onContextMenuHandler);
			cm.hideBuiltInItems();

			// OFC CREDITS
			var fs:ContextMenuItem = new ContextMenuItem("Charts by Open Flash Chart [Version "+VERSION+"]" );
			fs.addEventListener(
				ContextMenuEvent.MENU_ITEM_SELECT,
				function doSomething(e:ContextMenuEvent):void {
					var url:String = "http://teethgrinder.co.uk/open-flash-chart-2/";
					var request:URLRequest = new URLRequest(url);
					flash.net.navigateToURL(request, '_blank');
				});
			cm.customItems.push( fs );
			
			//var save_image_message:String = ( this.chart_parameters['save_image_message'] ) ? this.chart_parameters['save_image_message'] : 'Save Image Locally';
			
			//var dl:ContextMenuItem = new ContextMenuItem(save_image_message);
			//dl.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, this.saveImage);
			//cm.customItems.push( dl );
			
			this.contextMenu = cm;
		}
		
		public function format_y_axis_label( val:Number ): String {
//			if( this._y_format != undefined )
//			{
//				var tmp:String = _root._y_format.replace('#val#',_root.format(val));
//				tmp = tmp.replace('#val:time#',_root.formatTime(val));
//				tmp = tmp.replace('#val:none#',String(val));
//				tmp = tmp.replace('#val:number#', NumberUtils.formatNumber (Number(val)));
//				return tmp;
//			}
//			else
				return NumberUtils.format(val,2,true,true,false);
		}


	}
	
}
