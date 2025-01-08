class MediafluxComponent {
  constructor(element) {
    this.element = element;
  }

  setOnline(value) {
    this.online = value;
    if (this.online) {
      this.element.classList.add('active');
      this.element.classList.remove('inactive');
    } else {
      this.element.classList.add('inactive');
      this.element.classList.remove('active');
    }
  }
}

export default MediafluxComponent;
