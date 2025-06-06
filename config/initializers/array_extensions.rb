class Array
  def mean
    return nil if empty?
    values = compact # Remove nil values
    return nil if values.empty?
    values.sum.to_f / values.size
  end
end 