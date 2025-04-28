import { render, screen } from '@testing-library/react';
import PagePlaceholder from '@/pages/components/PagePlaceholder';

describe('PagePlaceholder', () => {
  it('renders the title', () => {
    render(<PagePlaceholder title="Test Title" />);
    expect(screen.getByText('Test Title')).toBeInTheDocument();
  });
});
