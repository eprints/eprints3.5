const EPJS_limit_names_shown_load = ( button_id, element_id ) => {
	button = document.getElementById(button_id);
	element = document.getElementById(element_id);

	button.style.display = "inline";
	button.setAttribute("aria-expanded", "true");
	element.style.display = "none";
	element.setAttribute("aria-hidden", "true");
}

const EPJS_limit_names_shown = ( button_id, element_id, button_unexpanded_text, button_expanded_text ) => {
    button = document.getElementById(button_id);
    element = document.getElementById(element_id);

    if( element.style.display == "inline" )
    {
		element.style.display = "none";
		element.setAttribute("aria-hidden", "true");
		button.setAttribute("aria-expanded", "false");
		if ( button_expanded_text != "" )
		{
			button.update( button_unexpanded_text );
		}
    }
    else
    {
		element.style.display = "inline";
		element.setAttribute("aria-hidden", "false");
		button.setAttribute("aria-expanded", "true");
		if ( button_expanded_text == "" )
		{
			button.style.display = "none";
		}
		else
		{
			button.update( button_expanded_text );
		}
		
    }
}
