class Lightbox {
	images = {};
	currentGroup = null;
	currentIndex = null;

	// Set up the lightbox on any link with the class `className`
	constructor(className) {
		const fragment = document.createRange().createContextualFragment(`
<div id="overlay" style="display: none;"></div>
<div id="lightbox" style="display: none;"><div id="outerImageContainer" style="width: 660px;"><div id="imageContainer"><img id="lightboxImage" alt="Lightbox"><div id="lightboxMovie" alt="Lightbox"></div><div id="loading"><img src="/style/images/lightbox/loading.gif" alt="Loading"></div></div></div><div id="imageDataContainer" style="width: 660px;"><div id="imageData"><div id="hoverNav"><a id="prevLink" href="#"></a><a id="nextLink" href="#"></a></div><div id="imageDetails"><span id="caption"></span><span id="numberDisplay"></span></div><div id="bottomNav"><a id="bottomNavClose" href="#"><img src="/style/images/lightbox/closelabel.gif" alt="Close"></a></div></div></div></div>`
		);

		Lightbox.overlayElement = fragment.getElementById('overlay');
		Lightbox.lightboxElement = fragment.getElementById('lightbox');

		Lightbox.outerImageContainer = fragment.getElementById('outerImageContainer');
		Lightbox.lightboxImage = fragment.getElementById('lightboxImage');
		Lightbox.loadingSpinner = fragment.getElementById('loading');

		Lightbox.imageDataContainer = fragment.getElementById('imageDataContainer');
		Lightbox.captionSpan = fragment.getElementById('caption');
		Lightbox.prevButton = fragment.getElementById('prevLink');
		Lightbox.nextButton = fragment.getElementById('nextLink');
		Lightbox.closeButton = fragment.getElementById('bottomNavClose');

		// Add the overlay and lightbox to the bottom of the page
		// (in such a way as to not break DOM references)
		document.querySelector('body').appendChild(fragment);

		// Close if the overlay, lightbox or close button is pressed.
		Lightbox.overlayElement.addEventListener('click', this.close);
		Lightbox.closeButton.addEventListener('click', this.close);
		// We only want to close on the lightbox if the event hasn't
		// bubbled as this means we have clicked off to the side whereas if
		// it bubbles then we clicked somewhere on the image or its border.
		Lightbox.lightboxElement.addEventListener('click', (ev) => {
			if (ev.srcElement === ev.currentTarget) this.close(ev);
		});

		Lightbox.prevButton.addEventListener('click', (ev) => {
			this.prev();
			ev.preventDefault();
		});
		Lightbox.nextButton.addEventListener('click', (ev) => {
			this.next();
			ev.preventDefault();
		});

		for (const element of document.getElementsByClassName(className)) {
			const group = element.getAttribute('data-group');
			if (this.images[group] === undefined) { this.images[group] = []; }
			const index = this.images[group].length;
			this.images[group].push({
				src: element.getAttribute('href'),
				caption: element.getAttribute('data-caption'),
			});

			element.addEventListener('click', (ev) => {
				this.show(group, index);
				ev.preventDefault();
			});
		}
	}

	// Show the lightbox for the `index`th element from `group`
	show(group, index) {
		const overlay = Lightbox.overlayElement;
		overlay.style.width = Math.max(document.body.scrollWidth, self.innerWidth) + 'px';
		overlay.style.height = Math.max(document.body.scrollHeight, self.innerHeight) + 'px';

		// Fade from 0.0 to 0.8 over the course of 200ms
		overlay.style.opacity = 0;
		let fadeIndex = 0;
		const intervalId = setInterval(() => {
			fadeIndex++;
			overlay.style.opacity = 0.04 * fadeIndex;
			overlay.style.display = '';
			if (fadeIndex === 20) {
				clearInterval(intervalId);
			}
		}, 10);

		Lightbox.lightboxElement.style.top =
			document.documentElement.scrollTop + (window.innerHeight / 10) + 'px';
		Lightbox.lightboxElement.style.display = '';

		Lightbox.lightboxImage.style.display = 'none';
		Lightbox.prevButton.style.display = 'none';
		Lightbox.nextButton.style.display = 'none';

		Lightbox.keyHandler = (ev) => { this.handleKey(ev); };
		document.addEventListener('keydown', Lightbox.keyHandler);

		this.setImage(group, index);
	}

	setImage(group, index) {
		if (group === this.currentGroup && index === this.currentIndex) {
			this.showImage();
			return;
		}

		// Prevent the page from being changed while the image is loading
		this.currentIndex = null;

		Lightbox.loadingSpinner.style.display = '';

		// We create the new image separately and then swap it in once it has
		// finished 'decoding' so that there are no flickers while it loads and it
		// ensures it is the correct size.
		const newImage = new Image();
		newImage.src = this.images[group][index].src;
		newImage.decode().then(() => {
			this.currentGroup = group;
			this.currentIndex = index;
			Lightbox.captionSpan.innerHTML = this.images[group][index].caption;

			const newWidth = newImage.width + 20 + 'px';

			Lightbox.outerImageContainer.style.width = newWidth;
			Lightbox.outerImageContainer.style.height = newImage.height + 'px';

			Lightbox.imageDataContainer.style.width = newWidth;

			// Duplicate the relevant attributes and then swap the elements.
			newImage.id = Lightbox.lightboxImage.id;
			newImage.alt = Lightbox.lightboxImage.alt;
			Lightbox.lightboxImage.replaceWith(newImage);
			Lightbox.lightboxImage = newImage;

			this.showImage();
			Lightbox.loadingSpinner.style.display = 'none';
		});
	}

	// Unhide the image and relevant `Prev` and `Next` buttons
	showImage() {
		Lightbox.lightboxImage.style.display = '';
		Lightbox.prevButton.style.display = this.currentIndex === 0 ? 'none' : '';
		Lightbox.nextButton.style.display =
			this.currentIndex === this.images[this.currentGroup].length - 1 ? 'none' : '';
	}

	prev() {
		if (this.currentIndex === null) return;
		if (this.currentIndex === 0) return;

		this.setImage(this.currentGroup, this.currentIndex - 1);
	}

	next() {
		if (this.currentIndex === null) return;
		if (this.currentIndex === this.images[this.currentGroup].length - 1) return;

		this.setImage(this.currentGroup, this.currentIndex + 1);
	}

	// Close the lightbox and fade the overlay out
	close(ev) {
		// Fade the overlay from 0.8 to 0.0 in 200ms
		let fadeIndex = 0;
		const intervalId = setInterval(() => {
			fadeIndex++;
			Lightbox.overlayElement.style.opacity = 0.8 - 0.04 * fadeIndex;
			if (fadeIndex === 20) {
				Lightbox.overlayElement.style.display = 'none';
				clearInterval(intervalId);
			}
		}, 10);

		Lightbox.lightboxElement.style.display = 'none';

		document.removeEventListener('keydown', Lightbox.keyHandler);

		// This is often a '#' link so if we don't prevent default it jumps to
		// the top of the page when closing.
		ev.preventDefault();
	}

	handleKey(ev) {
		switch (ev.key) {
			case 'Escape':
				this.close(ev);
				break;
			case 'ArrowLeft':
				this.prev();
				break;
			case 'ArrowRight':
				this.next();
				break;
		}
	}
}

document.addEventListener('DOMContentLoaded', () => {
	new Lightbox('lightbox');
});

