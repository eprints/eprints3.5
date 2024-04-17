/*
 *
 * Simple Progress Bar Widget
 *
 * Usage:
 *
 * var epb = new EPrintsProgressBar({}, container);
 *
 * epb.update( .3, '30%' );
 */

class EPrintsProgressBar {
	constructor(opts, container) {
		this.opts = {};
		this.container = container;
		this.img_path = eprints_http_root + '/style/images/';

		this.current = 0;
		this.progress = 0;

		this.opts.bar = opts.bar == null ? 'progress_bar.png' : opts.bar;
		this.opts.border = opts.border == null ? 'progress_border.png' : opts.border;
		this.opts.show_text = opts.show_text == null ? 0 : opts.show_text;

		this.img = document.createElement( 'img' );
		this.container.appendChild( this.img );

		this.onload();
		this.img.src = this.img_path + this.opts.border;
		this.img.classList.add( 'ep_progress_bar' );
	}

	onload() {
		this.img.style.background = 'url(' + this.img_path + this.opts.bar + ') top left no-repeat';
		this.img.style.backgroundPosition = '-200px 0px';
		this.update( this.progress, 'progress bar for upload' );
	}

	update(progress, alt) {
		if( progress == null || progress < 0 || progress > 1 ) return;

		this.progress = progress;
		this.img.setAttribute( 'alt', alt );

		this._update();
	}

	_update() {
		var width = outerWidth( this.img );
		if( !width ) return;

		var x_offset = Math.round( this.progress * width );
		if( x_offset != this.current )
		{
			this.current = x_offset;
		}
		this.img.style.backgroundPosition = (this.current-width) + 'px 0px';
	}
};
