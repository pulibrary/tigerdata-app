// @vitest-environment jsdom

import {
  // assert,
  describe, expect, it,
} from 'vitest';
// import { setTargetHtml } from '../entrypoints/helper';

describe('helper', () => {
  it('has a window', () => {
    expect(typeof window).not.toBe('undefined');
  });
});
