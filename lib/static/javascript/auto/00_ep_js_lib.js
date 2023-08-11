/**
 * EPrints - Vanilla JS DOM tools library
 * 
 * @since  3.5.0
 * @version 1.0.0
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
 * @return {undefined} n/a Void function
 */
const appearEffect = (element, duration, steps) => {
        element.style.opacity = "0";
        element.style.display = "";

	let delay = duration / steps;
	let opacity = 0;
	let opacityIncrease = 1 / steps;
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
const slideDownEffect = (element, duration, steps) => {
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
const slideUpEffect = (element, duration, steps, callback) => {
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



