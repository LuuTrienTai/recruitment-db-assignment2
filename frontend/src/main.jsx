import { createRoot } from 'react-dom/client';
import 'bootstrap/dist/css/bootstrap.min.css';
import './styles.css';
import JobPostingsPage from './pages/JobPostingsPage.jsx';

createRoot(document.getElementById('root')).render(<JobPostingsPage />);
