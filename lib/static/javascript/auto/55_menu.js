// EPJS_Menus - inspired from http://javascript-array.com/scripts/simple_drop_down_menu/
// 
// To create a menu, simply add the attribute "menu = 'some_id'" to the anchor that will trigger the menu, and create a div:
//	<div id="some_id" style="display:none;">
//                <a>Some links</a> etc...
//	</div>

class EPJS_Menus {
	anchors = null
	anchor_timer_id = null
	timer_id = null
	current_menu = null
	default_timeout = 100

	constructor(params) {
		this.anchors = {};

		document.querySelectorAll("a[menu]").forEach((el) => {
                	var menu_id = el.getAttribute( 'menu' );
                	if( menu_id == null )
                	        return false;

                	var menu = document.getElementById( menu_id );
                	if( menu == null )
                	        return false;

                	menu.style.display = "none";

			var anchor_id = el.getAttribute( 'id' );
                	if( anchor_id == null || anchor_id == "" )
                	{
                	        anchor_id = 'anchor_' + Math.floor(Math.random()*12345);
                	        el.id =  anchor_id;
                	}

	                // store a mapping menu_id => anchor_id (anchor_id is the id of the element being hover-ed)
        	        this.anchors[menu_id] = anchor_id;

                	// Event handlers
			el.addEventListener( 'mouseover', (el) => this.open(el, menu_id) )
			el.addEventListener( 'mouseout', (el) => this.close_timeout(el, menu_id) )

			menu.addEventListener( 'mouseover', (menu) => this.cancel_timeout(el, menu_id) )
			menu.addEventListener( 'mouseout', (menu) => this.close_timeout(el, menu_id) )
		})

		document.addEventListener( 'click', () => this.close(this) )
	}

	open(event) {
		event.preventDefault()
		event.stopPropagation()

		let args = arguments
		let menu_id = args[1]

        	// cancel close timer
        	this.cancel_timeout();

        	// close current menu
        	if( this.current_menu != null )
        	{
        	        this.current_menu.style.display = "none";
        	        document.getElementById( this.anchors[this.current_menu.id] ).classList.remove( 'ep_tm_menu_selected' );
        	}

		this.current_menu = document.getElementById( menu_id )
		this.current_menu.style.zIndex = 1
		this.current_menu.style.display = ""

        	document.getElementById( this.anchors[menu_id] ).classList.add( 'ep_tm_menu_selected' );	
	}

	close(event) {
        	if( this.current_menu != null )
        	{
        	        this.current_menu.style.display = "none";
        	        document.getElementById( this.anchors[this.current_menu.id] ).classList.remove( 'ep_tm_menu_selected' );
        	}

        	return false;
	}

	close_timeout(event) {
		this.timer_id = setTimeout(() => { document.getElementById( this.current_menu.id ).style.display = "none" }, this.default_timeout)
		this.anchor_timer_id = setTimeout(() => { document.getElementById( this.anchors[this.current_menu.id] ).classList.remove( "ep_tm_menu_selected" ) }, this.default_timeout)
	}

	cancel_timeout(event) {
        	if(this.timer_id)
        	{
        	        window.clearTimeout(this.timer_id);
        	        this.timer_id = null;
        	}
        	if(this.anchor_timer_id)
        	{
        	        window.clearTimeout(this.anchor_timer_id);
        	        this.anchor_timer_id = null;
        	}
	}
}

var EPJS_menu_template;
window.onload = (event) => {
	EPJS_menu_template = new EPJS_Menus();
};


