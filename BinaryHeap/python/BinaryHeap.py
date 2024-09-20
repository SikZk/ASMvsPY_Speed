class BinaryHeap:
    def __init__(self):
        self.heap = []

    def insert(self, node):
        self.heap.append(node)
        self._move_up_the_heap_(len(self.heap) - 1)

    def _swap_heap_nodes_(self, index1, index2):
        temp = self.heap[index1]
        self.heap[index1] = self.heap[index2]
        self.heap[index2] = temp

    def _move_up_the_heap_(self, node_index):
        parent_node_index = (node_index - 1) // 2
        current = node_index
        while parent_node_index >= 0 and self.heap[parent_node_index] > self.heap[current]:
            self._swap_heap_nodes_(parent_node_index, current)

            current = parent_node_index
            parent_node_index = (current - 1) // 2

    def _move_down_the_heap_(self, index):
        left_child_node_index = 2 * index + 1
        right_child_node_index = 2 * index + 2
        current = index

        if left_child_node_index < len(self.heap) and self.heap[left_child_node_index] < self.heap[current]:
            current = left_child_node_index

        if right_child_node_index < len(self.heap) and self.heap[right_child_node_index] < self.heap[current]:
            current = right_child_node_index

        if current != index:
            self._swap_heap_nodes_(index, current)
            self._move_down_the_heap_(current)

    def get_min(self):
        if len(self.heap) == 0:
            return None
        return self.heap[0]

    def delete_min(self):
        if len(self.heap) == 0:
            return None

        min_value = self.heap[0]
        self.heap[0] = self.heap[(len(self.heap) - 1)]
        self.heap.pop()
        self._move_down_the_heap_(0)

        return min_value

def read_data_from_file(filename):
    with open(filename, 'r') as f:
        return [int(line) for line in f]

def main():
    heap = BinaryHeap()
    data = read_data_from_file("./test.txt")
    for d in data:
        heap.insert(d)
    for i in range (1,1000):
        heap.delete_min()


if __name__ == "__main__":
    main()