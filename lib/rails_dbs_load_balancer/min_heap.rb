class MinHeap
    def initialize(comparator = lambda { |x, y| x.last <=> y.last })
        @comparator = comparator
        @items = []
    end

    def push(x)
        @items.push(x)
        swim_up(@items.size-1)
    end

    def pop
        @items[0], @items[@items.size-1] = @items[@items.size-1], @items[0]
        @items.pop.tap { sink_down(0) }
    end

    def peak
        @items[0]
    end

    def update(index, delta)
        item_index = @items.find_index { |item| item.first == index }
        @items[item_index][1] += delta
        
        if delta > 0
            swim_up(item_index)
        else
            sink_down(item_index)
        end
    end

    def empty?
        @items.empty?
    end

    private

        def parent(i)
            ((i-1)/2).floor
        end

        def left(i)
            2*i + 1
        end

        def swim_up(i)
            pi = parent(i)
            if pi >= 0 && @comparator.call(@items[i], @items[pi]) <= 0
                @items[pi], @items[i] = @items[i], @items[pi]
                swim_up(pi)
            end
        end

        def sink_down(i)
            return if (li = left(i)) >= @items.size
            ri = li + 1
            swap_i = (li == @items.size-1 || @comparator.call(@items[li], @items[ri]) <= 0) ? li : ri
            if (@comparator.call(@items[swap_i], @items[i]) <= 0)
                @items[swap_i], @items[i] = @items[i], @items[swap_i]
                sink_down(swap_i)
            end
        end
end
