const ep_autocompleter = (element, target, url, basenames, width_of_these, fields_to_send, extra_params) => {

	xhrAutocompleter(element, target, url, {
		callback: (el) => {
			w = width_of_these.reduce((acc, elem) => acc + elem.offsetWidth, 0)

			let target_elem = document.getElementById(target)
			target_elem.style.position = 'absolute';
			target_elem.style.width = w + 'px';

			document.getElementById(target + "_loading").style.width = w + 'px';

			let params = fields_to_send.reduce((acc, field_id) => {
				let field_elem = document.getElementById( basenames.relative + field_id )
				return acc + "&" + field_id + "=" + field_elem.value
			}, "q=" + el.value )

			return params + extra_params;
		},
		onShow: (element) => {
			let target_elem = element.parentNode.parentNode.querySelector('.ep_drop_target')
			appearEffect(target_elem, 150, 15)
		},
		updateElement: (selected) => {
			var ul = selected.querySelectorAll('ul')[0];
			var lis = ul.querySelectorAll('li');

			lis.forEach(function (li) {
				var myid = li.getAttribute('id');
				if (myid == null || myid == '') {
					return;
				}

				var attr = myid.split(/:/);
				if (attr[0] != 'for') {
					alert("Autocomplete id reference did not start with 'for': " + myid);
					return;
				}

				var id = attr[3];
				if (id == null) {
					id = '';
				}

				var prefix = basenames[attr[2]];
				if (prefix == null) {
					prefix = '';
				}

				var target = document.getElementById(prefix + id);
				if (attr[2] == 'row') {
					var parts = basenames['relative'].match(/^(.*_)([0-9]+)$/);
					var target_id = parts[1] + "cell_" + id + "_" + (parts[2] * 2 - 2);
					target = document.getElementById(target_id);
				}

				if (!target) {
					return;
				}

				if (attr[1] == 'hide') {
					target.style.display = 'none';
				} else if (attr[1] == 'show') {
					target.style.display = 'block';
				} else if (attr[1] == 'value') {
					var newvalue = li.innerHTML;
					rExp = /&gt;/gi;
					newvalue = newvalue.replace(rExp, ">");
					rExp = /&lt;/gi;
					newvalue = newvalue.replace(rExp, "<");
					rExp = /&amp;/gi;
					newvalue = newvalue.replace(rExp, "&");
					target.value = newvalue;
				} else if (attr[1] == 'block') {
					while (target.hasChildNodes()) {
						target.removeChild(target.firstChild);
					}
					while (li.hasChildNodes()) {
						target.appendChild(li.removeChild(li.firstChild));
					}
				} else {
					alert("1st part of autocomplete id ref was: " + attr[1]);
				}

			});
		}
	});
}
