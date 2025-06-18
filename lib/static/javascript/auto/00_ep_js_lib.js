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
const outerHeight = (element) => {
	var style = window.getComputedStyle(element);
	return element.offsetHeight + parseFloat(style.marginTop) + parseFloat(style.marginBottom);
};
const outerWidth = (element) => {
	var style = window.getComputedStyle(element);
	return element.offsetWidth + parseFloat(style.marginLeft) + parseFloat(style.marginRight);
};
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
	const heightDecrement = height / steps;
	const delay = duration / steps;

	const intervalID = setInterval(() => {
		height -= heightDecrement;
		element.style.height = height + 'px';
		steps--;
		if (steps == 0) {
			element.style.display = 'none';
			element.style.height = '';
			clearInterval(intervalID);
		}
	}, delay);
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
	element.style.height = '0px';
	element.style.display = 'block';

	const endHeight = outerHeight(inner);

	let height = 0;
	const heightDelta = endHeight / steps;
	const delay = duration / steps;
	let step = 0;

	const intervalID = setInterval(() => {
		height += heightDelta;
		element.style.height = height + 'px';
		step++;
		if (step == steps) {
			element.style.height = '';
			clearInterval(intervalID);
		}
	}, delay);
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
 * The element will increase opacity from 0 to 1 (or a specified value).
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
 * Close Effect e.g. fields using ep_autocompleter like creator in eprint workflow.
 * The element will decrease opacity from 1 to 0.
 *
 * @param {DOM Element} element The element which will decrease the opacity.
 * @param {number} duration Duration of the effect in milliseconds.
 * @param {number} steps Resolution of the effect.
 * @return {undefined} n/a Void function
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
 * Close effect for file tree's displayed in the eprint workflow.
 * 
 * @param {DOM Element} element The element being manipulated for the effect.
 * @param {number} duration Duration of the effect in milliseconds.
 * @param {number} steps Resultion of the effect.
 * @param {function} callback Executed at the end of the effect.
 * @return {undefined} n/a Void function
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
 * Slide up effect for dropdowns, such as those used in filter boxes and field information.
 * 
 * @param {DOM Element} element The element being manipulated for the effect.
 * @param {number} duration Duration of the effect in milliseconds.
 * @param {number} steps Resultion of the effect.
 * @param {function} callback Executed at the end of the effect.
 * @return {undefined} n/a Void function
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
 * Slide elements vertically, used in document reordering.
 *
 * @param {DOM Element} element The element being manipulated for the effect.
 * @param {number} startPosition Where relative to the elements potition the animation should start.
 * @param {number} newPosition Where relative to the elements potition the animation should end.
 * @param {number} duration Duration of the effect in milliseconds.
 * @param {number} steps Resultion of the effect.
 * @param {function} callback Executed at the end of the effect.
 * @return {undefined} n/a Void function
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
 * Find the closest parent node with a specified tag.
 *
 * @param {DOM Element} childElement The element whose parent we are looking for.
 * @param {string} targetTagName The tag name for the element we are looking for.
 * @return {DOM Element, undefined} The parent element or undefined if no parent element found.
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
 * Creates an attribute object from an element's attributes.
 *
 * @param {DOM Element} element The element whos attributes are being transposed into a hash.
 * @return {object} The attribute hash. 
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
 * Adds an object of attributes to an element.
 *
 * @param {DOM Element} element The element having the attributes added.
 * @param {object} attrsObj The object containing attributes as key value pairs.
 * @return {n/a} Void function as attribute are added directly to element.
 */
const setAttributes = (element, attrsObj) => {
	for(let key in attrsObj) {
		element.setAttribute(key, attrsObj[key]);
	}
}

/**
 * Serialize Form Data
 *
 * @param {DOM Element} form The form data being serialized.
 * @return {object} The serialized data as an object.
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
 * A helper function to get the dimensions of the current page.
 *
 * @return {array} An array containing the width then the hight of the body element.
 */
const getPageSizeArray = () => {
	let body = document.querySelector("body")

	return [
		body.scrollWidth,
		body.scrollHeight
	]
}

/**
 * An object containing the scroll position of the page in both axis.
 *
 * @return {object} An object containing the left and top position as string keys and array style keys.
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
 * Replacing Prototype's Ajax helpers with a simplified XMLHttpRequest function.
 *
 * @param {string} url The URL being requested.
 * @param {object} options An object containing callbacks for each stage of the request.
 * @return {n/a} nothing returned, void function.
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
		} else if ('onException' in options) {
			options.onException(this)
		}
	}

	xhr.onerror = function() { options.onFailure() };
}

/**
 * Replacing Prototype's autocompleter for the metafields in the eprints worflow.
 *
 * @param {DOM Element} text_field The field input i.e. the search string.
 * @param {string} id_of_div_to_populate The element to be populated with results.
 * @param {string} url The URL for the ajax request.
 * @param {object} options An object containing callbacks for each stage of the request.
 * @return {n/a} nothing returned, void function.
 */
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

/**
 * Generates a universal unique identifier.
 *
 * http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript
 * @return {string} Returns a string containing 32 characters of hex values.
 */
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
 * Format bytes into a friendly human-readable size.
 *
 * @param {number} size_in_bytes The size in bytes.
 * @return {string} The size using order of magnitude identifiers.
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
 * Periodically execute a callback function.
 *
 * @param {function} callback The function periodically executed.
 * @param {float} frequency How often the callback is executed.
 * @return {n/a} Void function.
 */
class periodicalExecuter {
  constructor(callback, frequency) {
    this.callback = callback;
    this.frequency = frequency;
    this.currentlyExecuting = false;

    this.registerCallback();
  }

  registerCallback() {
    this.timer = setInterval(this.onTimerEvent.bind(this), this.frequency * 1000);
  }

  execute() {
    this.callback(this);
  }

  stop() {
    if (!this.timer) return;
    clearInterval(this.timer);
    this.timer = null;
  }

  onTimerEvent() {
    if (!this.currentlyExecuting) {
      try {
        this.currentlyExecuting = true;
        this.execute();
        this.currentlyExecuting = false;
      } catch(e) {
        this.currentlyExecuting = false;
        throw e;
      }
    }
  }
};


/*
 * Get parameters set in the HTTP GET header
 *
 * @param {string} varible The variable name.
 * @return {string} If the header is found the function returns the variable associated.
 */
const getHeaderVariable = (variable) => {
        var query = window.location.search.substring(1);
        var vars = query.split("&");
        for (var i=0;i<vars.length;i++) {
                var pair = vars[i].split("=");
                if (pair[0] == variable) {
                        return decodeURIComponent(pair[1]);
                }
        }
}

/*
 * Required in place of lightbox code.
 * The following elements are injected into the page and used for overlays and lightbox style features.
 */
window.addEventListener('load', () => {
	// This can't just be done with body.innerHTML += `...` because then it will break any already loaded DOM references like listeners
	document.querySelector('body').insertAdjacentHTML('beforeend', `
<div id="overlay" style="display: none;"></div>
<div id="lightbox" style="display: none;"><div id="outerImageContainer"><div id="imageContainer"><img id="lightboxImage" alt="Lightbox"><div id="lightboxMovie" alt="Lightbox"></div><div id="loading"><a id="loadingLink" href="#"><img src="/style/images/lightbox/loading.gif" alt="Loading"></a></div></div></div><div id="imageDataContainer"><div id="imageData"><div id="hoverNav"><a id="prevLink"></a><a id="nextLink"></a></div><div id="imageDetails"><span id="caption"></span><span id="numberDisplay"></span></div><div id="bottomNav"><a id="bottomNavClose" href="#"><img src="/style/images/lightbox/closelabel.gif" alt="Close"></a></div></div></div></div>
`);
});

