# frozen_string_literal: true

RSpec.describe MinHeap do
    describe "push new items" do
        it "peak the minimum" do
            subject.push([2,1])
            subject.push([2,2])
            subject.push([3,3])
            subject.push([1,4])

            expect(subject.peak).to eq([1,4])
            expect(subject.peak).to eq([1,4])
        end
    
        it "pop the minimum" do
            subject.push([3,1])
            subject.push([2,2])
            subject.push([6,3])
            subject.push([4,4])

            expect(subject.pop).to eq([2,2])
            expect(subject.pop).to eq([3,1])
        end
    end

    describe "update exist items" do
        it "peak the minimum" do
            subject.push([1,1])
            subject.push([2,2])
            subject.push([3,3])
            subject.push([4,4])

            subject.increase(1, 2)
            expect(subject.peak).to eq([2,2])
            expect(subject.peak).to eq([2,2])

            subject.decrease(3, 2)
            expect(subject.peak).to eq([1,3])
            expect(subject.peak).to eq([1,3])
        end
    
        it "pop the minimum" do
            subject.push([1,1])
            subject.push([2,2])
            subject.push([3,3])
            subject.push([4,4])

            subject.decrease(3, 2)
            subject.increase(1, 2)
            expect(subject.pop).to eq([1,3])
            expect(subject.pop).to eq([2,2])
        end
    end

    describe "order" do
        it "return sorted db-indexes asc by db-val" do
            subject.push([2,1])
            subject.push([2,2])
            subject.push([3,3])
            subject.push([1,4])

            expect(subject.order).to eq([4,1,2,3])
        end
    end
end
