class Component_Field {
	constructor(prefix) {
		this.prefix = prefix;
		this.root = document.getElementById(this.prefix);
		this.form = this.root.closest('form');

		this.initialize_internal();
	}

	initialize_internal() {
		this.root.querySelectorAll('input.epjs_ajax').forEach ((input) => {
			if (input.type == 'image' ) {
				let attr = attributeHash(input);
				attr['onclick'] = "Component_Field_Action(this, '" + input.name + "', '" + input.value + "', '" + this.prefix + "')";
				let link = document.createElement('a');
				setAttributes(link, attr);
				let img = document.createElement('img');
				setAttributes(img, {
					src: attr['src'],
					alt: attr['alt']
				});
				link.appendChild(img);
				input.parentNode.replaceChild(link, input);
				input = link;
			}
			else {
				let attr = attributeHash(input);
				attr['type'] = 'button';
				attr['id'] = attr['name'];
				attr['onclick'] = "Component_Field_Action(this, '" + input.name + "', '" + input.value + "', '" + this.prefix + "')";
				let button = document.createElement('input');
				setAttributes(button, attr);
				input.parentNode.replaceChild(button, input);
				input = button;
			}
		});
	}
}

function Component_Field_Action(e, inputName, inputValue, prefix) {
	root = document.getElementById(prefix);
	form = root.closest('form');
	let params = serializeForm (form);
	params['component'] = prefix;
	params[inputName] = inputValue;
	params[prefix + '_export'] = 1;

	let container = document.getElementById(prefix + '_ajax_content_target');

	if (container == null) {
		container = document.getElementById(prefix + '_content');
	}

	let img = document.createElement('img');
	setAttributes(img, {
		src: eprints_http_root + '/style/images/loading.gif',
		style: 'position: absolute;'
	});
	container.insertBefore (img, container.firstChild);

	let url = eprints_http_cgiroot + '/users/home';
	xhrRequest(url, {
		method: form.method,
		onSuccess: ((response) => {
			let range = document.createRange();
			range.setStart(container, 0);
			container.replaceChildren(range.createContextualFragment(response.responseText));
		}),
		parameters: params,
	});
}

const EPJS_clear_row = (basename, index) => {
	const inputs = document.querySelectorAll(`input[id^=${basename}_${index}_],textarea#${basename}_${index}`);
	inputs.forEach((el) => {
		el.value = '';
		// Ensure the longtext word counter is updated
		el.dispatchEvent(new Event('input'));
	});

	const selects = document.querySelectorAll(`select[id^=${basename}_${index}_]`);
	selects.forEach((el) => {
		let foundDefault = false;
		for (const child of el.children) {
			if ( child.tagName == "OPTGROUP" ) {
				for (const gchild of child.children ) {
					if (gchild.dataset.default) {
						gchild.selected = true;
						foundDefault = true;
						break;
					}
				}
				if ( foundDefault ) {
					break;
				}
			}
			else {
				if (child.dataset.default) {
					child.selected = true;
					foundDefault = true;
					break;
				}
			}
		}
		if (!foundDefault && el.firstChild) {
			el.firstChild.selected = true;
		}
	});

	// We need to clear spans because 'contributions' use it (although we have
	// to be careful not to catch 'label' in the crossfire).
	const spans = document.querySelectorAll(`div[id^=${basename}_cell_]>div>span[id^=${basename}_${index}_]`);
	spans.forEach((el) => {
		el.innerHTML = '';
	});

	// Clear a richtext field if tinymce is defined
	if (tinymce) {
		const richtext = tinymce.get(`${basename}_${index}`);
		if (richtext) {
			richtext.setContent('');
		}
	}

	return false;
};

