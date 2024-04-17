/** ep_js_init_dl_tree
 * Add click-actions to DTs that open/close the related DD.
 *
 * @param root
 * @param className
 **/

const ep_js_init_dl_tree = (root, className) => {

	Array.from( document.getElementById(root).getElementsByTagName('*') ).forEach((ele) => {
		// ep_no_js won't be overridden by show()
		if( ele.nodeName == 'DD' && ele.classList.contains( 'ep_no_js' ) )
		{
			ele.style.display = "none";
			ele.classList.remove( 'ep_no_js' );
		}
		if( ele.nodeName != 'DT' ) return;
		ele.addEventListener( 'click' , () => {
			let dd = ele.nextElementSibling

			if( !dd || !dd.hasChildNodes() ) return;
			if( dd.style.display != 'none' ) {
                                ele.classList.remove( className );

				fileTreeCloseEffect(ele, 200, 50, () => {
					Array.from(dd.getElementsByTagName('*')).forEach((ele) => {
                                        	if( ele.nodeName == 'DT' ) {
                                                	ele.classList.remove( className );
						}
                                                if( ele.nodeName == 'DD' ) {
                                                        ele.style.display = "none";
						}
                                        });
				})
                        } else {
                                ele.classList.add( className );
				closeEffect(ele, 200, 50)
                        }
		})
	});
}
