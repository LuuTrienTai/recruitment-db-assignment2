const baseURL = (import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000').replace(/\/+$/, '');
const route = '/api/job-postings';

async function request(path, method = 'GET', payload) {
  let response;
  try {
    response = await fetch(`${baseURL}${path}`, {
      method,
      ...(payload && {
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      }),
    });
  } catch {
    throw new Error('The API could not be reached. Check that the backend is running.');
  }

  if (response.status === 204) return null;
  const body = await response.json().catch(() => null);
  if (!response.ok) {
    const detail = body?.detail;
    if (Array.isArray(detail)) {
      const first = detail[0];
      const field = first?.loc?.at(-1)?.toString().replaceAll('_', ' ');
      throw new Error(first ? `${field}: ${first.msg}` : 'Some fields are invalid.');
    }
    throw new Error(typeof detail === 'string' ? detail : `Request failed (HTTP ${response.status}).`);
  }
  return body;
}

export const JobPostings = {
  options: () => request(`${route}/form-options`),
  get: (id) => request(`${route}/${id}`),
  create: (data) => request(route, 'POST', data),
  update: (id, data) => request(`${route}/${id}`, 'PUT', data),
  remove: (id) => request(`${route}/${id}`, 'DELETE'),
};
