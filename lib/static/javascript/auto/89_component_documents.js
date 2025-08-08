class Component_Documents {
	prefix = null;
	panels = null;
	documents = [];

	constructor(prefix) {
		this.prefix = prefix;
		this.panels = document.getElementById(prefix + '_panels');
		Component_Documents.instances.push(this);
		var component = this;

		var form = this.panels.closest('form');
		this.form = form;

		this.panels.querySelectorAll('div.ep_upload_doc').forEach(function(doc_div) {
			var docid = component.initialize_panel(doc_div);

			component.documents.push({
				id: docid,
				div: doc_div
			});
		});

		this.format = '^' + this.prefix + '_doc([0-9]+)';
		this.initialize_sortable();

		// Lightbox options
		this.lightbox = document.getElementById('lightbox');
		//document.querySelector('body').innerHTML += '<div id="overlay" style="display: none;"></div>';
		this.overlay = document.getElementById('overlay');
		this.loading = document.getElementById('loading');
		this.lightboxMovie = document.getElementById('lightboxMovie');
		this.resizeDuration = 0.2;
		this.overlayDuration = 0.2;
		this.outerImageContainer = document.getElementById('outerImageContainer');
	}

	initialize_sortable() {
		var that = this;
		Sortable.create(document.getElementById(that.panels.id), {
			tag: 'div',
			only: 'ep_upload_doc',
			format: that.format,
			onUpdate: that.drag.bind(that)
		});
	}

	initialize_panel(panel) {
		var component = this;

		var exp = 'input[name="'+component.prefix+'_update_doc"]';
		var docid;
		panel.querySelectorAll(exp).forEach(function(input) {
			docid = input.value
		});

		panel.querySelectorAll('input[rel="interactive"], input[rel="automatic"]').forEach(function(input) {
			var type = input.getAttribute('rel');
			var attr = attributeHash(input);
			attr['href'] = '#'+component.prefix+'_update_doc';
			let link = document.createElement('a')
			setAttributes(link, attr)
			let img = document.createElement('img')
			setAttributes(img, {
				src: attr['src'],
				alt: attr['alt']
			});
			link.appendChild(img);

			link.addEventListener('click', () => this.start(this, link, docid, type ));

			input.replaceWith(link);
		}, this);

		return docid;
	}

	find_document_div(docid) {
		return document.getElementById(this.prefix + '_doc' + docid + '_block');
	}

	order() {
		var docids = [];
		this.panels.querySelectorAll("div > input[id$='_update_doc']").forEach((panel) => {
			docids.push(panel.value)
		})
		return docids;
	}

	drag(panels) {
		var url = eprints_http_cgiroot + '/users/home?';
		var action = '_internal_' + this.prefix + '_reorder';
		url += new URLSearchParams(new FormData(this.form)).toString();

		url += '&component=' + this.prefix;
		let order = this.order();
		url += '&' + this.prefix + '_order=' + order[0];
		url += '&' + this.prefix + '_order=' + order[1];
		url += '&' + action + '=1';

		xhrRequest(url, {
			method: 'get',
			onException: function(req, e) {
				throw e;
			},
			onSuccess: (function(transport) {
			}).bind(this),
		});
	}

	start(event, input, docid, type) {
		var component = this;
		var action = input.name;
		var url = eprints_http_cgiroot + '/users/home';

		var params = serializeForm(this.form);
		params['component'] = this.prefix;
		params[this.prefix + '_update_doc'] = docid;
		params[this.prefix + '_export'] = docid;
		params[action] = 1;

		if (type == 'automatic')
		{
			xhrRequest(url, {
				method: 'post',
				onException: function(response) {
					alert( "AJAX Exception: Status " + response.status + " " + response.statusText );
				},
				onSuccess: (function(response) {
					var json = JSON.parse(response.response);
					if (!json)
					{
						alert('Expected JSON but got: ' + response.response);
						return;
					}
					this.update_documents(json.documents);
					this.update_messages(json.messages);
				}).bind(this),
				parameters: params
			});
			return;
		}

		document.querySelectorAll('select, object, embed').forEach(function(node){ node.style.visibility = 'hidden' });

		var arrayPageSize = getPageSizeArray();
		this.overlay.style.width = arrayPageSize[0] + 'px';
		this.overlay.style.height = arrayPageSize[0] + 'px';

		appearEffect(this.overlay, 150, 15, 0.8)

        	// calculate top and left offset for the lightbox 
        	var arrayPageScroll = getScrollOffsetsObject();
        	var lightboxTop = arrayPageScroll[1] + (window.innerHeight / 10);
        	var lightboxLeft = arrayPageScroll[0];
        	document.getElementById('lightboxImage').style.display = 'none';
        	this.lightboxMovie.style.display = 'none';
		document.getElementById('hoverNav').style.display = 'none';
        	document.getElementById('prevLink').style.display = 'none';
        	document.getElementById('nextLink').style.display = 'none';
        	document.getElementById('imageDataContainer').style.opacity = '.0001';
		this.lightbox.style.top = lightboxTop + 'px';
		this.lightbox.style.left = lightboxLeft + 'px';
		this.lightbox.style.display = '';

		xhrRequest(url, {
			method: 'post',
			onException: function(response) {
				alert( "AJAX Exception: Status " + response.status + " " + response.statusText );
			},
			onSuccess: (function(transport) {
				this.loading.style.display = 'none';
				this.lightboxMovie = document.getElementById('lightboxMovie');
				this.lightboxMovie.innerHTML = transport.response;
			
				var boxWidth = this.lightboxMovie.offsetWidth;
				if( boxWidth == null || boxWidth < 640 ) {
					boxWidth = 640;
				}
				this.resizeImageContainer(boxWidth, this.lightboxMovie.offsetHeight);
				var form = document.getElementById('lightboxMovie').querySelector('form');
				if (!form.onsubmit)
				{
					form.onsubmit = function() { return false; };
					form.querySelectorAll('input[type="submit"], input[type="image"]').forEach(function(input) {
						input.addEventListener( 'click', (e) => {
							component.stop(e, input)
						} );
					});
				}
				document.getElementById('lightboxMovie').style.display = '';
			}).bind(this),
			parameters: params
		});
	}

	stop(event, input) {
		var form = input.closest('form');
		var params = serializeForm( form );

		params[input.name] = 1;
		params['export'] = 1;

		this.lightboxMovie.style.display = 'none';
		this.lightboxMovie.innerHTML = '';
		this.loading.style.display = '';

		var url = eprints_http_cgiroot + '/users/home';

		xhrRequest(url, {
			method: form.method,
			onException: function(response) {
				alert( "AJAX Exception: Status " + response.status + " " + response.statusText );
			},
			onSuccess: (function(transport) {
				this.lightbox.style.display = 'none';
				this.overlay.style.display = 'none';
				var json = JSON.parse(transport.response);
				if (!json)
				{
					alert ('Expected JSON but got: ' + transport.response);
					return;
				}
				this.update_documents(json.documents);
				this.update_messages(json.messages);
			}).bind(this),
			parameters: params
		});
	}

	resizeImageContainer(imgWidth, imgHeight) {
        	// get new width and height
        	var widthNew  = (imgWidth  + 10 * 2);
        	var heightNew = (imgHeight + 10 * 2);

		this.outerImageContainer.style.width = widthNew + 'px';
		this.outerImageContainer.style.height = heightNew + 'px';
	}

	update_messages(json) {
		var container = document.getElementById('ep_messages');
		if (!container) {
			return;
		}
		container.innerHTML = '';
		for(var i = 0; i < json.length; ++i) {
			container.innerHTML = json[i];
		}
	}

	remove_document(docid) {
		var doc_div = this.find_document_div(docid);
		if (!doc_div) {
			return false;
		}
		slideUpEffect(doc_div, 0.15, 50, () => {
			doc_div.remove()
		})
		return true;
	}

	update_documents(json) {
		var corder = this.order();
		var actions = [];
		// remove any deleted
		for (var i = 0; i < corder.length; ++i)
			for (var j = 0; j <= json.length; ++j)
				if (j == json.length )
				{
					this.remove_document(corder[i]);
					corder.splice(i, 1);
					--i;
				}
				else if (corder[i] == json[j].id){
					break;
				}
		// add any new or any forced-refreshes
		for (var i = 0; i < json.length; ++i)
			for (var j = 0; j <= corder.length; ++j)
				if (json[i].refresh)
				{
					this.refresh_document(json[i].id);
					break;
				}
				else if (j == corder.length)
				{
					this.refresh_document(json[i].id);
					corder.push(json[i].id);
					break;
				}
				else if (json[i].id == corder[j]){
					break;
				}
		// bubble-sort to reorder the documents in the order given in json
		var place = {};
		for (var i = 0; i < json.length; ++i){
			place[json[i].id] = parseInt(json[i].placement);
		}
		var swapped;
		do {
			swapped = false;
			for (var i = 0; i < corder.length-1; ++i)
				if (place[corder[i]] > place[corder[i+1]])
				{
					this.swap_documents(corder[i], corder[i+1]);
					var t = corder[i];
					corder[i] = corder[i+1];
					corder[i+1] = t;
					swapped = true;
				}
		} while (swapped);
	}

	swap_documents(left, right) {
		left = this.find_document_div(left);
		right = this.find_document_div(right);
		slideVertical(left, 0, getOffsetTop(right), 0.15, 50, () => {
			left.remove()
			right.parentNode.insertBefore (left, right.nextSibling);
		})
		slideVertical(right, 0, getOffsetTop(left), 0.15, 50, () => {
				this.initialize_sortable();
		})
	}

	refresh_document(docid) {
		var params = serializeForm(this.form);

		params['component'] = this.prefix;
		delete params[this.prefix + '_update_doc'];
		params[this.prefix + '_export'] = docid;

		/* create an empty div that will hold the document */
		var doc_div = this.find_document_div(docid);
		if (!doc_div)
		{
			doc_div = document.createElement('div')
			setAttributes(doc_div, {
				id: this.prefix + '_doc' + docid + '_block',
				'class': 'ep_upload_doc'	
			})
			this.panels.appendChild(doc_div);
		}
		else
		{
			let img = document.createElement('img');
			setAttributes(img, {
				src: eprints_http_root + '/style/images/lightbox/loading.gif',
				style: 'position: absolute;'	
			})
			doc_div.insertBefore(img, doc_div.firstChild );
		}

		var url = eprints_http_cgiroot + '/users/home';
		xhrRequest(url, {
			method: this.form.method,
			onException: function(response) {
				alert( "AJAX Exception: Status " + response.status + " " + response.statusText );
			},
			onSuccess: (function(transport) {
				let div = document.createElement('div')
				div.innerHTML = transport.responseText
				div = div.firstChild;
				div.style.display = 'none';
				this.initialize_panel(div);

				if (doc_div.hasChildNodes)
				{
					div.style.display = '';
					doc_div.replaceWith(div);
					this.initialize_sortable();
				}
				else
				{
					doc_div.replaceWith(div);
					slideVertical(div, -getOffsetTop(div), getOffsetTop(div), 0.15, 50, () => {
						this.initialize_sortable();
					})
				}
			}).bind (this),
			onFailure: (function(transport) {
				if (transport.status == 404)
				{
					if (this.remove_document(docid))
					{
						this.initialize_sortable();
					}
				}
			}).bind (this),
			parameters: params
		});
	}
};
Component_Documents.instances = [];
