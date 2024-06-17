import consumer from './consumer';
import MediafluxComponent from '../components';

const MEDIAFLUX_DOM_SELECTOR = '.mediaflux-status';

consumer.subscriptions.create({ channel: 'MediafluxChannel' }, {
  buildComponent() {
    const element = document.querySelector(MEDIAFLUX_DOM_SELECTOR);
    const component = new MediafluxComponent(element);
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
