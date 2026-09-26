const menus = Array.from(document.querySelectorAll<HTMLDetailsElement>('[data-landing-disclosure]'));
menus.forEach(menu => {
  menu.addEventListener('toggle', () => {
    if (menu.open) menus.forEach(other => { if (other !== menu) other.open = false; });
  });
  menu.querySelectorAll('a').forEach(link => link.addEventListener('click', () => { menu.open = false; }));
  menu.addEventListener('keydown', event => {
    if (event.key === 'Escape') { menu.open = false; menu.querySelector('summary')?.focus(); }
  });
  menu.addEventListener('focusout', event => {
    if (event.relatedTarget instanceof Node && !menu.contains(event.relatedTarget)) menu.open = false;
  });
});
document.addEventListener('pointerdown', event => {
  menus.forEach(menu => { if (event.target instanceof Node && !menu.contains(event.target)) menu.open = false; });
});
