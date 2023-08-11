/**
 * Document preview hover over
 */
const EPJS_ShowPreview = ( e, preview_id, position = 'right' ) => {
	var box = document.getElementById(preview_id);

	box.style.display = 'block';
	box.style.zIndex = 1000;

	var img = document.getElementById(preview_id+'_img');
        box.style.width = img.width + 'px';

	var elt = e.target;

	if ( position == 'left' )
	{
		clonePosition(box, elt, -(outerWidth(box)))
	}
	else
	{
		clonePosition(box, elt, outerWidth(elt));
	}
}

/**
 * Hide document preview hover over
 */
const EPJS_HidePreview = ( e, preview_id ) => {
	document.getElementById(preview_id).style.display = 'none';
}
