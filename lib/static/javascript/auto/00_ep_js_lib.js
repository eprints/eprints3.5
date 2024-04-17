/**
 * EPrints - Vanilla JS DOM tools library
 * 
 * @since  3.5.0
 *
 * @author Edward Oakley, EPrints Services
 *
 * @license This file is part of EPrints 3.4 L<http://www.eprints.org/>.
 * EPrints 3.4 and this file are released under the terms of the
 * GNU Lesser General Public License version 3 as published by
 * the Free Software Foundation unless otherwise stated.
 *
 * EPrints 3.4 is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with EPrints 3.4.
 * If not, see L<http://www.gnu.org/licenses/>.
 *
 */


/**
 * Helper Functions
 */
const outerHeight = (element) => element.offsetHeight + parseInt( element.style.marginTop ) + parseInt( element.style.marginBottom ) 
const outerWidth = (element) => element.offsetWidth + parseIntReturnNum( element.style.marginLeft ) + parseIntReturnNum( element.style.marginRight )
const getOffsetTop = (element) => element.getBoundingClientRect().top + window.scrollY;
const parseIntReturnNum = (input) => isNaN(parseInt(input)) === "number" ? parseInt(input) : 0;

/**
 * Close dropdown e.g. review page help or filter dropdowns.
 * The element will reduce in size from the current height down to 0.
 *
 * @param {DOM Element} element The element which will reduce in size.
 * @param {number} duration Duration of the effect in milliseconds.
 * @param {number} steps Resolution of the effect.
 * @return {undefined} n/a Void function
 */
const scaleEffectClose = (element, duration, steps) => {
        let height = element.offsetHeight;
        let heightDecrement = height / steps;
        let delay = duration / steps;

	(function effect() {
                setTimeout(function() {
                        height -= heightDecrement
                        element.style.height = height + 'px'
                        steps--
                        if (steps){
                                effect();
                        } else {
                                element.style.display = "none"
				element.style.height = ""
                        }
                }, delay )
        })();
};

/**
 * Open dropdown e.g. review page help or filter dropdowns.
 * The element will increase in size from 0 to current height of inner element
 * when that element is set to display block.
 *
 * @param {DOM Element} element The element which will increase in size.
 * @param {DOM Element} inner The inner element which will be used to match the size.
 * @param {number} duration Duration of the effect in milliseconds.
 * @param {number} steps Resolution of the effect.
 * @return {undefined} n/a Void function
 */
const scaleEffectOpen = (element, inner, duration, steps) => {
	element.style.height = "0px";
        element.style.display = "block";

	let endHeight = outerHeight(inner);

	let height = 0;
        let heightDelta = endHeight / steps;
        let delay = duration / steps;
	let step = 0;

        (function effect() {
                setTimeout(function() {
                        height += heightDelta
                        element.style.height = height + 'px'
                        step++
                        if (step < steps){
                                effect();
                        } else {
                                element.style.height = ""
                        }
                }, delay )
        })();
};

/**
 * Clone position e.g. previews on summary pages
 *
 * @param {DOM Element} element The element which will be moved.
 * @param {DOM Element} source The element whose position is being cloned.
 * @param {number} offsetLeft Number of pixels the clone should offset from the left.
 * @return {undefined} n/a Void function
 */
const clonePosition = (element, source, offsetLeft) => {
	offsetLeft = offsetLeft + source.getBoundingClientRect().left;
	element.style.left = offsetLeft + 'px';
	element.style.top = source.getBoundingClientRect().top + 'px';
}

/**
 * Appear Effect e.g. fields using ep_autocompleter like creator in eprint workflow.
 * The element will increase opacity from 0 to 1 element.
 *
 * @param {DOM Element} element The element which will increase the opacity.
 * @param {number} duration Duration of the effect in milliseconds.
 * @param {number} steps Resolution of the effect.
 * @param {number} finalOpacity the final opacity of the element once the effect has finished.
 * @return {undefined} n/a Void function
 */
const appearEffect = (element, duration, steps, finalOpacity) => {
        element.style.opacity = "0";
        element.style.display = "";
	finalOpacity = finalOpacity ? finalOpacity : 1;

	let delay = duration / steps;
	let opacity = 0;
	let opacityIncrease = finalOpacity / steps;
	let step = 0;

        (function effect() {
                setTimeout(function() {
                        opacity += opacityIncrease;
                        element.style.opacity = opacity;
                        step++
                        if (step < steps){
                                effect();
                        } else {
                                //element.style.opacity = ""
                        }
                }, delay )
        })();
};

/**
 *
 *
 */
const closeEffect = (element, duration, steps) => {
	let step = 0;
	let delay = duration / steps;

	let dd = element.nextElementSibling;
	let dl = dd.querySelector('dl')

	dd.style.display = "";
	dd.style.overflow = "hidden";
	dd.style.position = "relative";
	dd.style.height = "0px";
	let dd_height = 0;
        let dd_target_height = dl.getBoundingClientRect().height;
        let dd_height_increment = dd_target_height / steps;

	dl.style.position = "relative";
	dl.style.bottom = dd_target_height + "px";
	let dl_bottom = dd_target_height;

	(function effect() {
                setTimeout(function() {
                        dd_height += dd_height_increment;
                        dd.style.height = dd_height + "px";

			dl_bottom -= dd_height_increment;
			dl.style.bottom = dl_bottom + "px";

                        step++
                        if (step < steps){
                                effect();
                        } else {
				dd.style.overflow = "visible"
				dd.style.height = "fit-content"
                        }
                }, delay )
        })();
}

/**
 *
 *
 */
const fileTreeCloseEffect = (element, duration, steps, callback) => {
        let step = steps;
        let delay = duration / steps;

        let dd = element.nextElementSibling;
        let dl = dd.querySelector('dl')

        dd.style.display = "";
        dd.style.overflow = "hidden";
        dd.style.position = "relative";

	let dd_height = dd.getBoundingClientRect().height;
        let dd_target_height = 0;
        let dd_height_decrement = dd_height / steps;

        dl.style.position = "relative";
        dl.style.bottom = "0px";
        let dl_bottom = 0;

        (function effect() {
                setTimeout(function() {
                        dd_height -= dd_height_decrement;
                        dd.style.height = dd_height + "px";

			dl_bottom += dd_height_decrement;
                        dl.style.bottom = dl_bottom + "px";

                        step--
                        if (step > 0){
                                effect();
                        } else {
                                dd.style.display = "none"
                                dd.style.height = ""
				dd.style.overflow = ""
				dd.style.position = ""
				callback()
                        }
                }, delay )
        })();
}

/**
 *
 *
 */
const slideUpEffect = (element, duration, steps, callback) => {
        let step = steps;
        let delay = duration / steps;
	let elemHeight = element.getBoundingClientRect().height;
        let elemTargetHeight = 0;
        let elemHeightDecrement = elemHeight / steps;
	
        (function effect() {
                setTimeout(function() {
                        elemHeight -= elemHeightDecrement;
                        element.style.height = elemHeight + "px";

                        step--
                        if (step > 0){
                                effect();
                        } else {
                                element.style.display = "none"
                                element.style.height = ""
				element.style.overflow = ""
				element.style.position = ""
				callback()
                        }
                }, delay )
	})();
}

/**
 *
 *
 */
const slideVertical = (element, startPosition, newPosition, duration, steps, callback) => {
        let step = steps;
        let delay = duration / steps;


	let currentPosition = startPosition;
	let stepDistance = (newPosition - getOffsetTop(element)) / steps;

        (function effect() {
                setTimeout(function() {
			currentPosition += stepDistance;
			element.style.top = currentPosition + 'px';

                        step--
                        if (step > 0){
                                effect();
                        } else {
				element.style.top = '0px';
				callback()
                        }
                }, delay )
	})();
}


/**
 *
 *
 */
const findParentNode = (childElement, targetTagName) => {
	let depthProtection = "BODY";
	let parentElement = childElement.parentNode;

	if (parentElement.tagName.toUpperCase() === targetTagName.toUpperCase())
	{
		return parentElement;
	}
	else if (parentElement.tagName === depthProtection)
	{
		return;
	}
	else
	{
		return findParentNode(parentElement, targetTagName)
	}
}


/**
 *
 *
 *
 */
const attributeHash = (element) => {
	let attr = element.attributes;
	var hash = {};

	var whitelist = { 'name': true, 'id':true, 'style':true, 'value':true };

	for (let i = 0; i < attr.length; ++i)
	{
	        let name = attr[i].name;
	        if( attr[i] === undefined && !whitelist[attr[i].name]) continue;
	        hash[name] = element.getAttribute(name);
	}

	return hash;
}


/**
 *
 *
 *
 */
const setAttributes = (element, attrsObj) => {
	for(let key in attrsObj) {
		element.setAttribute(key, attrsObj[key]);
	}
}


/**
 *
 *
 *
 */
const serializeForm = (form) => {
	let serializedData = {}
	let formData = new FormData(form);

	for (let [name, value] of formData){
		serializedData[name] = value
	}

	return serializedData
}


/**
 *
 *
 *
 */
const getPageSizeArray = () => {
	let body = document.querySelector("body")

	return [
		body.scrollWidth,
		body.scrollHeight
	]
}


/**
 *
 *
 *
 */
const getScrollOffsetsObject = () => {

	return {
		0: window.scrollX,
		1: window.scrollY,
		'left': window.scrollX,
		'top': window.scrollY,
	}
}


/**
 *
 *
 *
 */
const xhrRequest = (url, options) => {
	const xhr = new XMLHttpRequest();

	let body = null;
	if('parameters' in options){
		body = new URLSearchParams(options.parameters);
	} else if ('parametersString' in options) {
		url += "?" + new URLSearchParams(options.parametersString).toString();
	} else if ('postBody' in options) {
		body = options.postBody;
	}

	xhr.open(options.method.toUpperCase(), url, true);
	xhr.send(body);

	xhr.onload = function(e) {
		if (this.status == 200) {
			options.onSuccess(this)
		} else {
			options.onException(this)
		}
	}

	xhr.onerror = function() { options.onFailure() };
}

const xhrAutocompleter = (text_field, id_of_div_to_populate, url, options) => {
	const xhr = new XMLHttpRequest();

	let indicator = document.getElementById(options.indicator);

	let div_to_populate = document.getElementById(id_of_div_to_populate);

	const clear_results = () => {
		div_to_populate.style.display = 'none';
		div_to_populate.innerHTML = '';
	}

	document.addEventListener('click', (e) => {
		if (!e.target.closest('#' + div_to_populate.id)){
			clear_results()
		}
	})

	text_field.addEventListener('input', (e) => {

		clear_results()

		xhrRequest(url, {
			method: 'GET',
			parametersString: options.callback(e.target),
			onSuccess: (response) => {
				div_to_populate.innerHTML = response.responseText;
				options.onShow(text_field)
				let lis = div_to_populate.querySelectorAll('li')
				lis.forEach((li) => {
					li.addEventListener('mouseenter', (e) => {
						lis.forEach((li_deselect) => {
							li_deselect.classList.remove('selected');
						})
						li.classList.add('selected')
					});
					li.addEventListener('click', (e) => {
						options.updateElement(li)
						clear_results()
					});
				});
			},
                        onException: (response) => {
				alert( "AJAX Exception: Status " + response.status + " " + response.statusText );
                        },
                        onFailure: (response) => {
                               	throw new Error ('Error ' + response.status + ' requesting phrases (check server log for details)');
                        },
		})

	});
	
}

// http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript
const generateUUID = () => {
        var s = [];
        var hexDigits = "0123456789ABCDEF";
        for(var i = 0; i < 32; i++)
                s[i] = hexDigits.substr(Math.floor(Math.random() * 0x10), 1);
        s[12] = "4";
        s[16] = hexDigits.substr((s[16] & 0x3) | 0x8, 1);

        return s.join("");
}

/*
 * Format @size as a friendly human-readable size
 */
const humanFilesize = (size_in_bytes) => {
        if( size_in_bytes < 4096 )
                return size_in_bytes + 'b';

        var size_in_k = Math.floor( size_in_bytes / 1024 );

        if( size_in_k < 4096 )
                return size_in_k + 'Kb';

        var size_in_meg = Math.floor( size_in_k / 1024 );

        if (size_in_meg < 4096)
                return size_in_meg + 'Mb';

        var size_in_gig = Math.floor( size_in_meg / 1024 );

        if (size_in_gig < 4096)
                return size_in_gig + 'Gb';

        var size_in_tb = Math.floor( size_in_gig / 1024 );

        return size_in_tb + 'Tb';
}


/*
 * Format @size as a friendly human-readable size
 */
const periodicalExecuter = (callback) => {
	//callback()
/*        (function execute() {
                setTimeout(function() {
                        step++
                        if (step < steps){
                                execute();
                        } else {
                                //element.style.opacity = ""
                        }
                }, delay )
	);
*/
}


/*
 *
 */
window.addEventListener('load', () => {
	document.querySelector('body').innerHTML += `
<div id="overlay" style="display: none;"></div>';
<div id="lightbox" style="display: none;"><div id="outerImageContainer" style="width: 250px; height: 250px;"><div id="imageContainer"><img id="lightboxImage" alt="Lightbox"><div id="lightboxMovie" alt="Lightbox"></div><div id="loading"><a id="loadingLink" href="#"><img src="https://vuir.vu.edu.au/style/images/lightbox/loading.gif" alt="Loading"></a></div></div></div><div id="imageDataContainer"><div id="imageData"><div id="hoverNav"><a id="prevLink"></a><a id="nextLink"></a></div><div id="imageDetails"><span id="caption"></span><span id="numberDisplay"></span></div><div id="bottomNav"><a id="bottomNavClose" href="#"><img src="https://vuir.vu.edu.au/style/images/lightbox/closelabel.gif" alt="Close"></a></div></div></div></div>
`
})
