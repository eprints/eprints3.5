/**
 * EPJS_toggle_aux helper functions
 */
const EPJS_toggleSlide = ( element_id, start_visible ) => EPJS_toggleSlide_aux( element_id, start_visible, null );
const EPJS_toggleSlideScroll = ( element_id, start_visible, scroll_id ) => EPJS_toggleSlide_aux( element_id, start_visible, scroll_id );

/**
 * EPJS_toggleSlide_aux function opens or closes dropdowns
 */
const EPJS_toggleSlide_aux = ( element_id, start_visible, scroll_id ) => {
	let element = document.getElementById(element_id);
	let inner = document.getElementById(element_id+"_inner");

	current_vis = start_visible;

	if( element.style.display == "none" )
	{
		current_vis = false;
	}
	else if( element.style.display == "block" )
	{
		current_vis = true;
	}


	element.style.overflow = 'hidden';
	if( current_vis )
	{
		scaleEffectClose(element, 300, 100)
	}
	else
	{
		scaleEffectOpen(element, inner, 300, 100);
	}
}

/**
 * EPJS_toggle_type helper function
 */
const EPJS_toggle = ( element_id, start_visible ) => EPJS_toggle_type( element_id, start_visible, 'block' );

/**
 * EPJS_toggle_type 
 */
function EPJS_toggle_type( element_id, start_visible, display_type )
{
	element = document.getElementById(element_id);

	current_vis = start_visible;

	if( element.style.display == "none" )
	{
		current_vis = false;
	}
	if( element.style.display == display_type )
	{
		current_vis = true;
	}
	
	if( current_vis )
	{
		element.style.display = "none";
	}
	else
	{
		element.style.display = display_type;
	}

}
