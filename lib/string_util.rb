
class String
  def starts_with?(prefix)
    prefix = prefix.to_s
    self[0, prefix.length] == prefix
  end

  def ends_with?(prefix)
    prefix = prefix.to_s
    self[-prefix.length, prefix.length] == prefix
  end
end
