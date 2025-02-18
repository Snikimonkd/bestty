module ring(<Type>);

struct Ring {
    usz written;
    usz head;
    Allocator allocator;
	Type[] buf;
}

fn void Ring.new_init(&self, usz size) {
    return self.init(size, allocator::heap());
}

fn void Ring.init(&self, usz size, Allocator allocator) {
    self.buf = allocator::new_array(allocator, Type, size);
    self.allocator = allocator;
}

fn void Ring.destroy(&self) {
    allocator::free(self.allocator, self.buf);
}

fn void Ring.push(&self, Type c) {
	if (self.written < self.buf.len()) {
		self.buf[self.written] = c;
		self.written++;
	} else {
		self.buf[self.head] = c;
		self.head = (self.head + 1) % self.buf.len();
	}
}

fn void Ring.pop(&self) {
    if (self.written > 0) {
        self.written--;
    }
}

macro Type Ring.@item_at(&self, usz index) @operator([]) {
	return self.buf[index];
}

fn Type* Ring.get_ref(&self, usz index) @operator(&[]) @inline {
	return &self.entries[index];
}

fn void Ring.set(&self, usz index, Type value) @operator([]=) {
	self.entries[index] = value;
}
