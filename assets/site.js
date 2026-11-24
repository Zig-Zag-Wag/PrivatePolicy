/* 中英文切换：写在 <html lang> 上，CSS 负责显隐，选择记在 localStorage。 */
(function () {
  var KEY = 'legal-lang';
  var root = document.documentElement;
  var buttons = document.querySelectorAll('[data-lang-set]');

  function apply(lang, persist) {
    root.lang = lang;
    for (var i = 0; i < buttons.length; i++) {
      buttons[i].setAttribute('aria-pressed', String(buttons[i].getAttribute('data-lang-set') === lang));
    }
    if (persist) {
      try { localStorage.setItem(KEY, lang); } catch (e) { /* 隐私模式下忽略 */ }
    }
  }

  buttons.forEach(function (button) {
    button.addEventListener('click', function () {
      apply(button.getAttribute('data-lang-set'), true);
    });
  });

  var saved = null;
  try { saved = localStorage.getItem(KEY); } catch (e) { /* 忽略 */ }

  if (saved) {
    apply(saved, false);
  } else if (!/^zh/i.test(navigator.language || '')) {
    apply('en', false);
  } else {
    apply(root.lang || 'zh-CN', false);
  }
})();
