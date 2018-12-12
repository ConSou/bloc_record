module BlocRecord
  class Collection < Array

    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end

    def take(x)
      self[0..x - 1]
    end

    def where(options={})
      attribute = options.keys.first
      value = options.values.first
      self.select {|h| h[attribute] == value}
    end

    def not(options={})
      attribute = options.keys.first
      value = options.values.first
      self.map do |h|
        if h[attribute] == value
          self.delete(h)
        else
          self
        end
      end
      self
    end

  end
end
