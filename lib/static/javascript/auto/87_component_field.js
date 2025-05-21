class Component_Field {
	constructor(prefix) {
		this.prefix = prefix;
		this.root = document.getElementById(this.prefix);
		this.form = findParentNode(this.root, 'form');

		this.initialize_internal();
	}

	initialize_internal() {
		document.querySelectorAll("#" + this.prefix + ' input.epjs_ajax').forEach ((input) => {
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
	form = findParentNode(root, 'form');
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
