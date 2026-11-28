import { useEffect, useRef, useState } from 'react';
import { JobPostings } from '../api/jobPostings.js';
import JobPostingForm, { formToPayload, jobToForm, newJob, validateJobForm } from '../components/JobPostingForm.jsx';

export default function JobPostingsPage() {
  const [options, setOptions] = useState(null);
  const [posting, setPosting] = useState(null);
  const [form, setForm] = useState(newJob);
  const [lookupId, setLookupId] = useState('');
  const [notice, setNotice] = useState(null);
  const [busy, setBusy] = useState(true);
  const deleteDialog = useRef(null);
  const feedback = useRef(null);

  async function run(action) {
    setBusy(true);
    setNotice(null);
    try {
      await action();
    } catch (error) {
      setNotice({ type: 'danger', message: error.message });
    } finally {
      setBusy(false);
    }
  }

  function loadOptions() {
    return run(async () => {
      const result = await JobPostings.options();
      setOptions(result);
      setForm(newJob(result.today));
    });
  }

  useEffect(() => { loadOptions(); }, []);
  useEffect(() => {
    if (notice) feedback.current?.scrollIntoView({ block: 'nearest' });
  }, [notice]);

  function clearPosting() {
    setPosting(null);
    setLookupId('');
    setForm(newJob(options.today));
  }

  function displayPosting(job) {
    setPosting(job);
    setLookupId(String(job.job_posting_id));
    setForm(jobToForm(job));
  }

  function loadPosting(event) {
    event.preventDefault();
    run(async () => displayPosting(await JobPostings.get(lookupId)));
  }

  function changeField(name, value) {
    setForm((current) => ({
      ...current,
      ...(name === 'company_id' ? { campaign_id: '' } : {}),
      [name]: value,
    }));
  }

  function savePosting(event) {
    event.preventDefault();
    const error = validateJobForm(form, options.today, !posting);
    if (error) {
      setNotice({ type: 'danger', message: error });
      return;
    }

    run(async () => {
      const data = formToPayload(form);
      const job = posting ? await JobPostings.update(posting.job_posting_id, data) : await JobPostings.create(data);
      displayPosting(job);
      setNotice({
        type: 'success',
        message: `Posting #${job.job_posting_id} ${posting ? 'updated' : 'created'}.`,
      });
    });
  }

  function deletePosting() {
    deleteDialog.current.close();
    run(async () => {
      await JobPostings.remove(posting.job_posting_id);
      clearPosting();
      setNotice({ type: 'success', message: `Posting #${posting.job_posting_id} deleted.` });
    });
  }

  return (
    <>
      <header className="site-header">
        <div className="page-width"><span className="brand">Recruitment</span></div>
      </header>
      <main className="page-width page-content">
        <div className="page-title">
          <h1>Job postings</h1>
          <button className="btn btn-success" disabled={!options || busy} onClick={() => {
            clearPosting();
            setNotice(null);
          }}>New posting</button>
        </div>
        <div className="workspace">
          <aside className="workspace-sidebar">
            <section className="panel lookup-panel" aria-labelledby="lookup-heading">
              <h2 id="lookup-heading">Find a posting</h2>
              <form onSubmit={loadPosting}>
                <label className="form-label" htmlFor="lookup-id">Posting ID</label>
                <div className="lookup-controls">
                  <input id="lookup-id" className="form-control" type="number" min="1" max="4294967295"
                    step="1" placeholder="e.g. 701" value={lookupId} required disabled={!options || busy}
                    onChange={(event) => setLookupId(event.target.value)} />
                  <button className="btn btn-outline-success" disabled={!options || busy}>Load</button>
                </div>
              </form>
            </section>
            {posting && (
              <section className="panel summary-panel" aria-labelledby="summary-heading">
                <h2 id="summary-heading">Posting #{posting.job_posting_id}</h2>
                <dl>
                  <div><dt>Status</dt><dd className={`status status-${posting.job_status}`}>{posting.job_status}</dd></div>
                  <div><dt>Applications</dt><dd>{posting.application_count}</dd></div>
                  <div><dt>Deadline</dt><dd>{posting.application_deadline}</dd></div>
                </dl>
              </section>
            )}
          </aside>

          <section className="panel editor" aria-labelledby="editor-heading">
            <div className="editor-heading">
              <h2 id="editor-heading">{posting ? `Edit posting #${posting.job_posting_id}` : 'Create a posting'}</h2>
            </div>
            {notice && (
              <div ref={feedback} className={`alert alert-${notice.type} feedback`} role={notice.type === 'danger' ? 'alert' : 'status'}>
                {notice.message}
              </div>
            )}
            {options ? (
              <JobPostingForm form={form} options={options} busy={busy} editing={Boolean(posting)}
                onChange={changeField} onSave={savePosting} onDelete={() => deleteDialog.current.showModal()} />
            ) : (
              <div className="feedback">
                {busy ? <p role="status">Loading form options…</p> :
                  <button className="btn btn-outline-success" onClick={loadOptions}>Retry connection</button>}
              </div>
            )}
          </section>
        </div>
      </main>

      <dialog ref={deleteDialog} aria-labelledby="delete-heading" className="delete-dialog">
        <h2 id="delete-heading">Delete posting #{posting?.job_posting_id}?</h2>
        <p>{posting?.title}</p>
        <p className="text-secondary">Postings with applications cannot be deleted.</p>
        <div className="dialog-actions">
          <form method="dialog"><button className="btn btn-light" autoFocus>Cancel</button></form>
          <button type="button" className="btn btn-danger" onClick={deletePosting}>Delete posting</button>
        </div>
      </dialog>
    </>
  );
}
