/**
 * EPJS_checkboxSlide(element_id, checkbox_id = element_id + '_checkbox')
 *
 * Slides dropdowns open and closed as with `EPJS_toggleSlide` and
 * `EPJS_toggleSlideScroll` but with much less javascript.
 *
 * This should be set up in the `on_click` of a checkbox (`checkbox_id`)
 * controlling a div (`element_id`) with the class `ep_toggleable` that
 * contains another div (`element_id + '_inner'`).
 */
const EPJS_checkboxSlide = (element_id, checkbox_id) => {
	const element = document.getElementById(element_id);
	const inner = document.getElementById(element_id + '_inner');

	checkbox_id ||= element_id + '_checkbox';
	const checkbox = document.getElementById(checkbox_id);

	if (checkbox.checked) {
		// Make sure the element is visible and has a height of 0 (otherwise it
		// may not expand properly).
		element.style.display = 'block';
		element.style.height = '0px';

		// Wait for 0ms so that it happens on the next event trigger, allowing
		// the `height = '0px'` from above to engage, if you set the height
		// twice within the same tick it will only listen to the second set so
		// won't do the animated expand.
		setTimeout(() => {
			// If reduced motion is set it won't do the transition so
			// `transitionend` will never be triggered.
			if (matchMedia('(prefers-reduced-motion: no-preference)').matches) {
				element.style.height = outerHeight(inner) + 'px';
				// Once the transition ends we set its height to `auto` so that
				// it can contain things like the help box expanding in a
				// collapsible element.
				element.addEventListener('transitionend', (ev) => {
					// We check that the element has size to ensure another
					// transition wasn't triggered midway through.
					if (element.offsetHeight != 0) {
						element.style.height = 'auto';
					}
				}, {once: true});
			} else {
				element.style.height = 'auto';
			}
		}, 0);
	} else {
		element.style.height = outerHeight(inner) + 'px';
		// As above we have to wait for 0ms to ensure the above set applies.
		setTimeout(() => {
			element.style.height = '0px';
		}, 0);
	}
};

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
