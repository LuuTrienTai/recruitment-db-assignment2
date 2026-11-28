const displayOptions = (options) => Object.entries(options).map(([value, label]) => ({ value, label }));
const saturday = displayOptions({ not_specified: 'Not specified', off: 'Off', working: 'Working' });
const employment = displayOptions({
  full_time: 'Full-time', part_time: 'Part-time', contract: 'Contract', internship: 'Internship',
});
const experience = displayOptions({
  no_experience: 'No experience', under_1_year: 'Under 1 year', '1_3_years': '1–3 years',
  '3_5_years': '3–5 years', over_5_years: 'Over 5 years',
});
const method = displayOptions({ on_site: 'On-site', external: 'External' });

export function newJob(today = '') {
  return {
    company_id: '', campaign_id: '', category_id: '', title: '', description: '',
    working_hours: '', saturday_work_policy: 'not_specified', job_level: '',
    required_experience: 'no_experience', min_salary: '', max_salary: '',
    employment_type: 'full_time', posted_date: today, application_deadline: '',
    application_method: 'on_site', contact_detail: '', employee_responsibilities: '', requirements: '',
  };
}

export function jobToForm(job) {
  return Object.fromEntries(Object.keys(newJob()).map((name) => [name, String(job[name] ?? '')]));
}

export function formToPayload(form) {
  return {
    ...form,
    company_id: Number(form.company_id),
    campaign_id: Number(form.campaign_id),
    category_id: Number(form.category_id),
    min_salary: form.min_salary || null,
    max_salary: form.max_salary || null,
    contact_detail: form.contact_detail.trim() || null,
  };
}

export function validateJobForm(form, today, creating) {
  if (creating && form.posted_date > today) return 'Posted date must be today or earlier.';
  if (form.application_deadline <= form.posted_date) return 'Application deadline must be later than the posted date.';
  if (creating && form.application_deadline < today) return 'A new posting must have a current or future deadline.';
  if (form.min_salary && form.max_salary && Number(form.min_salary) > Number(form.max_salary)) {
    return 'Minimum salary cannot exceed maximum salary.';
  }
  if (form.application_method === 'external' && !form.contact_detail.trim()) {
    return 'Contact details are required for an external application.';
  }
  return '';
}

function FormField({
  label, name, value, onChange, options, multiline, wide, optional, placeholder, ...attributes
}) {
  const props = {
    id: name,
    name,
    value,
    onChange: (event) => onChange(name, event.target.value),
    required: !optional,
    ...attributes,
  };

  return (
    <div className={wide ? 'form-field field-wide' : 'form-field'}>
      <label htmlFor={name} className="form-label">
        {label}{optional && <span className="field-note">Optional</span>}
      </label>
      {options ? (
        <select {...props} className="form-select">
          {placeholder && <option value="">{placeholder}</option>}
          {options.map(({ value, label }) => <option key={value} value={value}>{label}</option>)}
        </select>
      ) : multiline ? (
        <textarea {...props} className="form-control" rows={3} placeholder={placeholder} />
      ) : (
        <input {...props} className="form-control" placeholder={placeholder} />
      )}
    </div>
  );
}

export default function JobPostingForm({ form, options, busy, editing, onChange, onSave, onDelete }) {
  const field = (name, label, props) => (
    <FormField name={name} label={label} value={form[name]} onChange={onChange} {...props} />
  );
  const choices = (rows, key) => rows.map((row) => ({ value: row[key], label: row.name }));
  const campaigns = options.campaigns.filter((row) => String(row.company_id) === form.company_id);
  const salaryAttrs = { optional: true, type: 'number', min: '0.01', max: '9999999999.99', step: '0.01' };

  return (
    <form onSubmit={onSave}>
      <fieldset disabled={busy}>
        <section className="form-section" aria-labelledby="posting-details">
          <h3 id="posting-details">Posting details</h3>
          <div className="form-grid">
            {field('title', 'Job title', { wide: true, maxLength: 255, placeholder: 'e.g. Backend Engineer' })}
            {field('company_id', 'Company', {
              options: choices(options.companies, 'company_id'), placeholder: 'Select company',
            })}
            {field('campaign_id', 'Campaign', {
              options: choices(campaigns, 'campaign_id'),
              placeholder: form.company_id ? 'Select campaign' : 'Select a company first',
              disabled: !form.company_id,
            })}
            {field('category_id', 'Specialisation', {
              options: choices(options.categories, 'category_id'), placeholder: 'Select specialisation',
            })}
            {field('job_level', 'Job level', { maxLength: 50, placeholder: 'e.g. Mid-level' })}
            {field('employment_type', 'Employment type', { options: employment })}
            {field('required_experience', 'Required experience', { options: experience })}
            {field('working_hours', 'Working hours', { maxLength: 100, placeholder: 'e.g. 09:00–18:00' })}
            {field('saturday_work_policy', 'Saturday work', { options: saturday })}
            {field('min_salary', 'Minimum salary (VND)', salaryAttrs)}
            {field('max_salary', 'Maximum salary (VND)', salaryAttrs)}
          </div>
        </section>
        <section className="form-section" aria-labelledby="applications">
          <h3 id="applications">Applications</h3>
          <div className="form-grid">
            {field('posted_date', 'Posted date', { type: 'date', max: editing ? undefined : options.today })}
            {field('application_deadline', 'Application deadline', { type: 'date', min: editing ? undefined : options.today })}
            {field('application_method', 'Application method', { options: method })}
            {field('contact_detail', 'Contact details', {
              optional: form.application_method !== 'external', maxLength: 255, placeholder: 'Email, phone or URL',
            })}
          </div>
        </section>
        <section className="form-section" aria-labelledby="role-overview">
          <h3 id="role-overview">Role overview</h3>
          <div className="form-grid">
            {field('description', 'Job description', { wide: true, multiline: true })}
            {field('employee_responsibilities', 'Responsibilities', { wide: true, multiline: true, maxLength: 255 })}
            {field('requirements', 'Requirements', { wide: true, multiline: true })}
          </div>
        </section>
        <div className="form-actions">
          {editing && <button className="btn btn-outline-danger" type="button" onClick={onDelete}>Delete posting</button>}
          <button className="btn btn-success ms-auto" type="submit">
            {busy ? 'Working…' : editing ? 'Save changes' : 'Create posting'}
          </button>
        </div>
      </fieldset>
    </form>
  );
}
