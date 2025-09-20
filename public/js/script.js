function showTopic(id) {
  document.querySelectorAll('.topic').forEach(el => el.classList.remove('active'));
  document.getElementById(id).classList.add('active');

  document.querySelectorAll('.nav button').forEach(b => b.classList.remove('active'));
  const btn = document.getElementById('btn-' + id);
  if (btn) btn.classList.add('active');

  // Scroll to top of content on switch
  document.querySelector('.content').scrollTo({ top: 0, behavior: 'smooth' });
}

function filterNav(q) {
  q = (q || '').toLowerCase();
  const items = [
    ['linux','🐧 Linux'],
    ['jenkins','🤖 Jenkins'],
    ['kubernetes','⚓ Kubernetes']
  ];
  items.forEach(([id, label]) => {
    const btn = document.getElementById('btn-' + id);
    btn.style.display = label.toLowerCase().includes(q) ? '' : 'none';
  });
}
