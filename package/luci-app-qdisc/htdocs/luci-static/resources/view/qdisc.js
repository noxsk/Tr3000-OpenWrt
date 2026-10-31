'use strict';
'require form';
'require view';

return view.extend({
	render: function() {
		var m, s, o;

		m = new form.Map('qdisc', _('Queue discipline'),
			_('Choose the TCP congestion control and the default packet queue.'));

		s = m.section(form.NamedSection, 'config', 'qdisc');
		s.anonymous = true;

		o = s.option(form.ListValue, 'tcp_cca', _('TCP congestion control'));
		o.value('cubic', 'CUBIC');
		o.value('bbr', 'BBR');
		o.default = 'bbr';
		o.rmempty = false;

		o = s.option(form.ListValue, 'qdisc', _('Queue discipline'));
		o.value('fq', 'FQ');
		o.value('cake', 'CAKE');
		o.value('fq_pie', 'FQ-PIE');
		o.default = 'fq';
		o.rmempty = false;

		return m.render();
	}
});
