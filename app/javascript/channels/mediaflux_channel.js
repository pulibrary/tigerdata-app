import consumer from './consumer';

class MediafluxStatusComponent {
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

consumer.subscriptions.create({ channel: 'MediafluxChannel' }, {
  buildComponent() {
    const element = document.querySelector('.mediaflux-status');
    const component = new MediafluxStatusComponent(element);
    this.component = component;
  },
  connected() {
    this.perform('update_state');
  },
  received(data) {
    if (!this.component) {
      this.buildComponent();
    }

    this.component.setOnline(data.state);
  },
});
