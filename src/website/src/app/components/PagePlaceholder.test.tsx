import { render, screen } from '@testing-library/react';
import PagePlaceholder from '@/app/components/PagePlaceholder';

describe('PagePlaceholder', () => {
  it('renders the title', () => {
    render(<PagePlaceholder title="Test Title" />);
    expect(screen.getByText('Test Title')).toBeInTheDocument();
  });
});
