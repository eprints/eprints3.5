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
const outerHeight = (element) => element.offsetHeight + parseInt( element.getStyle("margin-top") ) + parseInt( element.getStyle("margin-bottom") ) 
const outerWidth = (element) => element.offsetWidth + parseInt( element.getStyle("margin-left") ) + parseInt( element.getStyle("margin-right") ) 
const getOffsetTop = (element) => element.getBoundingClientRect().top + window.scrollY;


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
	        hash[name] = element.readAttribute(name);
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
async function fetchRequest(url, options) {
	console.log('requesting with fetch', url, options)

	try {
		const res = await fetch(url, {
			method:	options.method.toUpperCase(),
			body:	new URLSearchParams(options.parameters),
		});

		if (!res.ok){
			console.log('call onFailure()')
			options.onFailure();
		} else {
			console.log('call onSuccess()')
			options.onSuccess(res)
		}

		const response = await res;
	} catch(error) {
		options.onException(url, error)
	}
}

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
