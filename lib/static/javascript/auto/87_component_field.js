class Component_Field {
	constructor(prefix) {
		this.prefix = prefix;
		this.root = document.getElementById(this.prefix);
		this.form = findParentNode(this.root, 'form');

		this.initialize_internal();
	}

	initialize_internal() {
		this.root.select ('input.epjs_ajax').forEach ((input) => {
			if (input.type == 'image' ) {
				let attr = attributeHash(input);
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
				let button = document.createElement('input');
				setAttributes(button, attr);
				input.parentNode.replaceChild(button, input);
				input = button;
			}
			input.addEventListener('click', (e) => this.internal(e, input));
		});
	}

	internal(e, input) {
		let params = serialize_form (this.form);
		params['component'] = this.prefix;
		params[input.name] = input.value;
		params[this.prefix + '_export'] = 1;

		let container = document.getElementById(this.prefix + '_ajax_content_target');

		if (container == null) {
			container = document.getElementById(this.prefix + '_content');
		}

		let img = document.createElement('img');
		setAttributes(img, {
			src: eprints_http_root + '/style/images/loading.gif',
                        style: 'position: absolute;'
		});
		container.insertBefore (img, container.firstChild);

		let url = eprints_http_cgiroot + '/users/home';
		new Ajax.Updater(container, url, {
			method: this.form.method,
			onComplete: (() => {
				this.initialize_internal();
			}),
			parameters: params,
			evalScripts: true
		});
	}
}
