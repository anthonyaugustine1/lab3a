
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 18 00       	mov    $0x180000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 b0 11 f0       	mov    $0xf011b000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 08             	sub    $0x8,%esp
f0100047:	e8 1b 01 00 00       	call   f0100167 <__x86.get_pc_thunk.bx>
f010004c:	81 c3 e0 f8 07 00    	add    $0x7f8e0,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c0 00 20 18 f0    	mov    $0xf0182000,%eax
f0100058:	c7 c2 e0 10 18 f0    	mov    $0xf01810e0,%edx
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 f3 4e 00 00       	call   f0104f5c <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 4f 05 00 00       	call   f01005bd <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 74 5a f8 ff    	lea    -0x7a58c(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 93 38 00 00       	call   f0103915 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 68 12 00 00       	call   f01012ef <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100087:	e8 2c 32 00 00       	call   f01032b8 <env_init>
	trap_init();
f010008c:	e8 37 39 00 00       	call   f01039c8 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100091:	83 c4 08             	add    $0x8,%esp
f0100094:	6a 00                	push   $0x0
f0100096:	ff b3 f4 ff ff ff    	push   -0xc(%ebx)
f010009c:	e8 ec 33 00 00       	call   f010348d <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a1:	83 c4 04             	add    $0x4,%esp
f01000a4:	c7 c0 54 13 18 f0    	mov    $0xf0181354,%eax
f01000aa:	ff 30                	push   (%eax)
f01000ac:	e8 79 37 00 00       	call   f010382a <env_run>

f01000b1 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000b1:	55                   	push   %ebp
f01000b2:	89 e5                	mov    %esp,%ebp
f01000b4:	56                   	push   %esi
f01000b5:	53                   	push   %ebx
f01000b6:	e8 ac 00 00 00       	call   f0100167 <__x86.get_pc_thunk.bx>
f01000bb:	81 c3 71 f8 07 00    	add    $0x7f871,%ebx
	va_list ap;

	if (panicstr)
f01000c1:	83 bb b4 17 00 00 00 	cmpl   $0x0,0x17b4(%ebx)
f01000c8:	74 0f                	je     f01000d9 <_panic+0x28>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000ca:	83 ec 0c             	sub    $0xc,%esp
f01000cd:	6a 00                	push   $0x0
f01000cf:	e8 df 07 00 00       	call   f01008b3 <monitor>
f01000d4:	83 c4 10             	add    $0x10,%esp
f01000d7:	eb f1                	jmp    f01000ca <_panic+0x19>
	panicstr = fmt;
f01000d9:	8b 45 10             	mov    0x10(%ebp),%eax
f01000dc:	89 83 b4 17 00 00    	mov    %eax,0x17b4(%ebx)
	asm volatile("cli; cld");
f01000e2:	fa                   	cli    
f01000e3:	fc                   	cld    
	va_start(ap, fmt);
f01000e4:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f01000e7:	83 ec 04             	sub    $0x4,%esp
f01000ea:	ff 75 0c             	push   0xc(%ebp)
f01000ed:	ff 75 08             	push   0x8(%ebp)
f01000f0:	8d 83 8f 5a f8 ff    	lea    -0x7a571(%ebx),%eax
f01000f6:	50                   	push   %eax
f01000f7:	e8 19 38 00 00       	call   f0103915 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	56                   	push   %esi
f0100100:	ff 75 10             	push   0x10(%ebp)
f0100103:	e8 d6 37 00 00       	call   f01038de <vcprintf>
	cprintf("\n");
f0100108:	8d 83 0a 62 f8 ff    	lea    -0x79df6(%ebx),%eax
f010010e:	89 04 24             	mov    %eax,(%esp)
f0100111:	e8 ff 37 00 00       	call   f0103915 <cprintf>
f0100116:	83 c4 10             	add    $0x10,%esp
f0100119:	eb af                	jmp    f01000ca <_panic+0x19>

f010011b <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010011b:	55                   	push   %ebp
f010011c:	89 e5                	mov    %esp,%ebp
f010011e:	56                   	push   %esi
f010011f:	53                   	push   %ebx
f0100120:	e8 42 00 00 00       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100125:	81 c3 07 f8 07 00    	add    $0x7f807,%ebx
	va_list ap;

	va_start(ap, fmt);
f010012b:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f010012e:	83 ec 04             	sub    $0x4,%esp
f0100131:	ff 75 0c             	push   0xc(%ebp)
f0100134:	ff 75 08             	push   0x8(%ebp)
f0100137:	8d 83 a7 5a f8 ff    	lea    -0x7a559(%ebx),%eax
f010013d:	50                   	push   %eax
f010013e:	e8 d2 37 00 00       	call   f0103915 <cprintf>
	vcprintf(fmt, ap);
f0100143:	83 c4 08             	add    $0x8,%esp
f0100146:	56                   	push   %esi
f0100147:	ff 75 10             	push   0x10(%ebp)
f010014a:	e8 8f 37 00 00       	call   f01038de <vcprintf>
	cprintf("\n");
f010014f:	8d 83 0a 62 f8 ff    	lea    -0x79df6(%ebx),%eax
f0100155:	89 04 24             	mov    %eax,(%esp)
f0100158:	e8 b8 37 00 00       	call   f0103915 <cprintf>
	va_end(ap);
}
f010015d:	83 c4 10             	add    $0x10,%esp
f0100160:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100163:	5b                   	pop    %ebx
f0100164:	5e                   	pop    %esi
f0100165:	5d                   	pop    %ebp
f0100166:	c3                   	ret    

f0100167 <__x86.get_pc_thunk.bx>:
f0100167:	8b 1c 24             	mov    (%esp),%ebx
f010016a:	c3                   	ret    

f010016b <serial_proc_data>:

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010016b:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100170:	ec                   	in     (%dx),%al
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100171:	a8 01                	test   $0x1,%al
f0100173:	74 0a                	je     f010017f <serial_proc_data+0x14>
f0100175:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010017a:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010017b:	0f b6 c0             	movzbl %al,%eax
f010017e:	c3                   	ret    
		return -1;
f010017f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f0100184:	c3                   	ret    

f0100185 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100185:	55                   	push   %ebp
f0100186:	89 e5                	mov    %esp,%ebp
f0100188:	57                   	push   %edi
f0100189:	56                   	push   %esi
f010018a:	53                   	push   %ebx
f010018b:	83 ec 1c             	sub    $0x1c,%esp
f010018e:	e8 6a 05 00 00       	call   f01006fd <__x86.get_pc_thunk.si>
f0100193:	81 c6 99 f7 07 00    	add    $0x7f799,%esi
f0100199:	89 c7                	mov    %eax,%edi
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
		cons.buf[cons.wpos++] = c;
f010019b:	8d 1d f4 17 00 00    	lea    0x17f4,%ebx
f01001a1:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
f01001a4:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01001a7:	89 7d e4             	mov    %edi,-0x1c(%ebp)
	while ((c = (*proc)()) != -1) {
f01001aa:	eb 25                	jmp    f01001d1 <cons_intr+0x4c>
		cons.buf[cons.wpos++] = c;
f01001ac:	8b 8c 1e 04 02 00 00 	mov    0x204(%esi,%ebx,1),%ecx
f01001b3:	8d 51 01             	lea    0x1(%ecx),%edx
f01001b6:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01001b9:	88 04 0f             	mov    %al,(%edi,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001bc:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01001c7:	0f 44 d0             	cmove  %eax,%edx
f01001ca:	89 94 1e 04 02 00 00 	mov    %edx,0x204(%esi,%ebx,1)
	while ((c = (*proc)()) != -1) {
f01001d1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01001d4:	ff d0                	call   *%eax
f01001d6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d9:	74 06                	je     f01001e1 <cons_intr+0x5c>
		if (c == 0)
f01001db:	85 c0                	test   %eax,%eax
f01001dd:	75 cd                	jne    f01001ac <cons_intr+0x27>
f01001df:	eb f0                	jmp    f01001d1 <cons_intr+0x4c>
	}
}
f01001e1:	83 c4 1c             	add    $0x1c,%esp
f01001e4:	5b                   	pop    %ebx
f01001e5:	5e                   	pop    %esi
f01001e6:	5f                   	pop    %edi
f01001e7:	5d                   	pop    %ebp
f01001e8:	c3                   	ret    

f01001e9 <kbd_proc_data>:
{
f01001e9:	55                   	push   %ebp
f01001ea:	89 e5                	mov    %esp,%ebp
f01001ec:	56                   	push   %esi
f01001ed:	53                   	push   %ebx
f01001ee:	e8 74 ff ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01001f3:	81 c3 39 f7 07 00    	add    $0x7f739,%ebx
f01001f9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001fe:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001ff:	a8 01                	test   $0x1,%al
f0100201:	0f 84 f7 00 00 00    	je     f01002fe <kbd_proc_data+0x115>
	if (stat & KBS_TERR)
f0100207:	a8 20                	test   $0x20,%al
f0100209:	0f 85 f6 00 00 00    	jne    f0100305 <kbd_proc_data+0x11c>
f010020f:	ba 60 00 00 00       	mov    $0x60,%edx
f0100214:	ec                   	in     (%dx),%al
f0100215:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f0100217:	3c e0                	cmp    $0xe0,%al
f0100219:	74 64                	je     f010027f <kbd_proc_data+0x96>
	} else if (data & 0x80) {
f010021b:	84 c0                	test   %al,%al
f010021d:	78 75                	js     f0100294 <kbd_proc_data+0xab>
	} else if (shift & E0ESC) {
f010021f:	8b 8b d4 17 00 00    	mov    0x17d4(%ebx),%ecx
f0100225:	f6 c1 40             	test   $0x40,%cl
f0100228:	74 0e                	je     f0100238 <kbd_proc_data+0x4f>
		data |= 0x80;
f010022a:	83 c8 80             	or     $0xffffff80,%eax
f010022d:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010022f:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100232:	89 8b d4 17 00 00    	mov    %ecx,0x17d4(%ebx)
	shift |= shiftcode[data];
f0100238:	0f b6 d2             	movzbl %dl,%edx
f010023b:	0f b6 84 13 f4 5b f8 	movzbl -0x7a40c(%ebx,%edx,1),%eax
f0100242:	ff 
f0100243:	0b 83 d4 17 00 00    	or     0x17d4(%ebx),%eax
	shift ^= togglecode[data];
f0100249:	0f b6 8c 13 f4 5a f8 	movzbl -0x7a50c(%ebx,%edx,1),%ecx
f0100250:	ff 
f0100251:	31 c8                	xor    %ecx,%eax
f0100253:	89 83 d4 17 00 00    	mov    %eax,0x17d4(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f0100259:	89 c1                	mov    %eax,%ecx
f010025b:	83 e1 03             	and    $0x3,%ecx
f010025e:	8b 8c 8b f4 16 00 00 	mov    0x16f4(%ebx,%ecx,4),%ecx
f0100265:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100269:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f010026c:	a8 08                	test   $0x8,%al
f010026e:	74 61                	je     f01002d1 <kbd_proc_data+0xe8>
		if ('a' <= c && c <= 'z')
f0100270:	89 f2                	mov    %esi,%edx
f0100272:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f0100275:	83 f9 19             	cmp    $0x19,%ecx
f0100278:	77 4b                	ja     f01002c5 <kbd_proc_data+0xdc>
			c += 'A' - 'a';
f010027a:	83 ee 20             	sub    $0x20,%esi
f010027d:	eb 0c                	jmp    f010028b <kbd_proc_data+0xa2>
		shift |= E0ESC;
f010027f:	83 8b d4 17 00 00 40 	orl    $0x40,0x17d4(%ebx)
		return 0;
f0100286:	be 00 00 00 00       	mov    $0x0,%esi
}
f010028b:	89 f0                	mov    %esi,%eax
f010028d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100290:	5b                   	pop    %ebx
f0100291:	5e                   	pop    %esi
f0100292:	5d                   	pop    %ebp
f0100293:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f0100294:	8b 8b d4 17 00 00    	mov    0x17d4(%ebx),%ecx
f010029a:	83 e0 7f             	and    $0x7f,%eax
f010029d:	f6 c1 40             	test   $0x40,%cl
f01002a0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002a3:	0f b6 d2             	movzbl %dl,%edx
f01002a6:	0f b6 84 13 f4 5b f8 	movzbl -0x7a40c(%ebx,%edx,1),%eax
f01002ad:	ff 
f01002ae:	83 c8 40             	or     $0x40,%eax
f01002b1:	0f b6 c0             	movzbl %al,%eax
f01002b4:	f7 d0                	not    %eax
f01002b6:	21 c8                	and    %ecx,%eax
f01002b8:	89 83 d4 17 00 00    	mov    %eax,0x17d4(%ebx)
		return 0;
f01002be:	be 00 00 00 00       	mov    $0x0,%esi
f01002c3:	eb c6                	jmp    f010028b <kbd_proc_data+0xa2>
		else if ('A' <= c && c <= 'Z')
f01002c5:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c8:	8d 4e 20             	lea    0x20(%esi),%ecx
f01002cb:	83 fa 1a             	cmp    $0x1a,%edx
f01002ce:	0f 42 f1             	cmovb  %ecx,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d1:	f7 d0                	not    %eax
f01002d3:	a8 06                	test   $0x6,%al
f01002d5:	75 b4                	jne    f010028b <kbd_proc_data+0xa2>
f01002d7:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f01002dd:	75 ac                	jne    f010028b <kbd_proc_data+0xa2>
		cprintf("Rebooting!\n");
f01002df:	83 ec 0c             	sub    $0xc,%esp
f01002e2:	8d 83 c1 5a f8 ff    	lea    -0x7a53f(%ebx),%eax
f01002e8:	50                   	push   %eax
f01002e9:	e8 27 36 00 00       	call   f0103915 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f3:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f8:	ee                   	out    %al,(%dx)
}
f01002f9:	83 c4 10             	add    $0x10,%esp
f01002fc:	eb 8d                	jmp    f010028b <kbd_proc_data+0xa2>
		return -1;
f01002fe:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100303:	eb 86                	jmp    f010028b <kbd_proc_data+0xa2>
		return -1;
f0100305:	be ff ff ff ff       	mov    $0xffffffff,%esi
f010030a:	e9 7c ff ff ff       	jmp    f010028b <kbd_proc_data+0xa2>

f010030f <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010030f:	55                   	push   %ebp
f0100310:	89 e5                	mov    %esp,%ebp
f0100312:	57                   	push   %edi
f0100313:	56                   	push   %esi
f0100314:	53                   	push   %ebx
f0100315:	83 ec 1c             	sub    $0x1c,%esp
f0100318:	e8 4a fe ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010031d:	81 c3 0f f6 07 00    	add    $0x7f60f,%ebx
f0100323:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f0100326:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010032b:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100330:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100335:	89 fa                	mov    %edi,%edx
f0100337:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100338:	a8 20                	test   $0x20,%al
f010033a:	75 13                	jne    f010034f <cons_putc+0x40>
f010033c:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100342:	7f 0b                	jg     f010034f <cons_putc+0x40>
f0100344:	89 ca                	mov    %ecx,%edx
f0100346:	ec                   	in     (%dx),%al
f0100347:	ec                   	in     (%dx),%al
f0100348:	ec                   	in     (%dx),%al
f0100349:	ec                   	in     (%dx),%al
	     i++)
f010034a:	83 c6 01             	add    $0x1,%esi
f010034d:	eb e6                	jmp    f0100335 <cons_putc+0x26>
	outb(COM1 + COM_TX, c);
f010034f:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100353:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100356:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010035b:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010035c:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100361:	bf 79 03 00 00       	mov    $0x379,%edi
f0100366:	b9 84 00 00 00       	mov    $0x84,%ecx
f010036b:	89 fa                	mov    %edi,%edx
f010036d:	ec                   	in     (%dx),%al
f010036e:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100374:	7f 0f                	jg     f0100385 <cons_putc+0x76>
f0100376:	84 c0                	test   %al,%al
f0100378:	78 0b                	js     f0100385 <cons_putc+0x76>
f010037a:	89 ca                	mov    %ecx,%edx
f010037c:	ec                   	in     (%dx),%al
f010037d:	ec                   	in     (%dx),%al
f010037e:	ec                   	in     (%dx),%al
f010037f:	ec                   	in     (%dx),%al
f0100380:	83 c6 01             	add    $0x1,%esi
f0100383:	eb e6                	jmp    f010036b <cons_putc+0x5c>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100385:	ba 78 03 00 00       	mov    $0x378,%edx
f010038a:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f010038e:	ee                   	out    %al,(%dx)
f010038f:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100394:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100399:	ee                   	out    %al,(%dx)
f010039a:	b8 08 00 00 00       	mov    $0x8,%eax
f010039f:	ee                   	out    %al,(%dx)
		c |= 0x0700;
f01003a0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01003a3:	89 f8                	mov    %edi,%eax
f01003a5:	80 cc 07             	or     $0x7,%ah
f01003a8:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f01003ae:	0f 45 c7             	cmovne %edi,%eax
f01003b1:	89 c7                	mov    %eax,%edi
f01003b3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f01003b6:	0f b6 c0             	movzbl %al,%eax
f01003b9:	89 f9                	mov    %edi,%ecx
f01003bb:	80 f9 0a             	cmp    $0xa,%cl
f01003be:	0f 84 e4 00 00 00    	je     f01004a8 <cons_putc+0x199>
f01003c4:	83 f8 0a             	cmp    $0xa,%eax
f01003c7:	7f 46                	jg     f010040f <cons_putc+0x100>
f01003c9:	83 f8 08             	cmp    $0x8,%eax
f01003cc:	0f 84 a8 00 00 00    	je     f010047a <cons_putc+0x16b>
f01003d2:	83 f8 09             	cmp    $0x9,%eax
f01003d5:	0f 85 da 00 00 00    	jne    f01004b5 <cons_putc+0x1a6>
		cons_putc(' ');
f01003db:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e0:	e8 2a ff ff ff       	call   f010030f <cons_putc>
		cons_putc(' ');
f01003e5:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ea:	e8 20 ff ff ff       	call   f010030f <cons_putc>
		cons_putc(' ');
f01003ef:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f4:	e8 16 ff ff ff       	call   f010030f <cons_putc>
		cons_putc(' ');
f01003f9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fe:	e8 0c ff ff ff       	call   f010030f <cons_putc>
		cons_putc(' ');
f0100403:	b8 20 00 00 00       	mov    $0x20,%eax
f0100408:	e8 02 ff ff ff       	call   f010030f <cons_putc>
		break;
f010040d:	eb 26                	jmp    f0100435 <cons_putc+0x126>
	switch (c & 0xff) {
f010040f:	83 f8 0d             	cmp    $0xd,%eax
f0100412:	0f 85 9d 00 00 00    	jne    f01004b5 <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f0100418:	0f b7 83 fc 19 00 00 	movzwl 0x19fc(%ebx),%eax
f010041f:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100425:	c1 e8 16             	shr    $0x16,%eax
f0100428:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010042b:	c1 e0 04             	shl    $0x4,%eax
f010042e:	66 89 83 fc 19 00 00 	mov    %ax,0x19fc(%ebx)
	if (crt_pos >= CRT_SIZE) {
f0100435:	66 81 bb fc 19 00 00 	cmpw   $0x7cf,0x19fc(%ebx)
f010043c:	cf 07 
f010043e:	0f 87 98 00 00 00    	ja     f01004dc <cons_putc+0x1cd>
	outb(addr_6845, 14);
f0100444:	8b 8b 04 1a 00 00    	mov    0x1a04(%ebx),%ecx
f010044a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010044f:	89 ca                	mov    %ecx,%edx
f0100451:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100452:	0f b7 9b fc 19 00 00 	movzwl 0x19fc(%ebx),%ebx
f0100459:	8d 71 01             	lea    0x1(%ecx),%esi
f010045c:	89 d8                	mov    %ebx,%eax
f010045e:	66 c1 e8 08          	shr    $0x8,%ax
f0100462:	89 f2                	mov    %esi,%edx
f0100464:	ee                   	out    %al,(%dx)
f0100465:	b8 0f 00 00 00       	mov    $0xf,%eax
f010046a:	89 ca                	mov    %ecx,%edx
f010046c:	ee                   	out    %al,(%dx)
f010046d:	89 d8                	mov    %ebx,%eax
f010046f:	89 f2                	mov    %esi,%edx
f0100471:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100472:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100475:	5b                   	pop    %ebx
f0100476:	5e                   	pop    %esi
f0100477:	5f                   	pop    %edi
f0100478:	5d                   	pop    %ebp
f0100479:	c3                   	ret    
		if (crt_pos > 0) {
f010047a:	0f b7 83 fc 19 00 00 	movzwl 0x19fc(%ebx),%eax
f0100481:	66 85 c0             	test   %ax,%ax
f0100484:	74 be                	je     f0100444 <cons_putc+0x135>
			crt_pos--;
f0100486:	83 e8 01             	sub    $0x1,%eax
f0100489:	66 89 83 fc 19 00 00 	mov    %ax,0x19fc(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100490:	0f b7 c0             	movzwl %ax,%eax
f0100493:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f0100497:	b2 00                	mov    $0x0,%dl
f0100499:	83 ca 20             	or     $0x20,%edx
f010049c:	8b 8b 00 1a 00 00    	mov    0x1a00(%ebx),%ecx
f01004a2:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f01004a6:	eb 8d                	jmp    f0100435 <cons_putc+0x126>
		crt_pos += CRT_COLS;
f01004a8:	66 83 83 fc 19 00 00 	addw   $0x50,0x19fc(%ebx)
f01004af:	50 
f01004b0:	e9 63 ff ff ff       	jmp    f0100418 <cons_putc+0x109>
		crt_buf[crt_pos++] = c;		/* write the character */
f01004b5:	0f b7 83 fc 19 00 00 	movzwl 0x19fc(%ebx),%eax
f01004bc:	8d 50 01             	lea    0x1(%eax),%edx
f01004bf:	66 89 93 fc 19 00 00 	mov    %dx,0x19fc(%ebx)
f01004c6:	0f b7 c0             	movzwl %ax,%eax
f01004c9:	8b 93 00 1a 00 00    	mov    0x1a00(%ebx),%edx
f01004cf:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004d3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
f01004d7:	e9 59 ff ff ff       	jmp    f0100435 <cons_putc+0x126>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004dc:	8b 83 00 1a 00 00    	mov    0x1a00(%ebx),%eax
f01004e2:	83 ec 04             	sub    $0x4,%esp
f01004e5:	68 00 0f 00 00       	push   $0xf00
f01004ea:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004f0:	52                   	push   %edx
f01004f1:	50                   	push   %eax
f01004f2:	e8 ab 4a 00 00       	call   f0104fa2 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004f7:	8b 93 00 1a 00 00    	mov    0x1a00(%ebx),%edx
f01004fd:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100503:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100509:	83 c4 10             	add    $0x10,%esp
f010050c:	66 c7 00 20 07       	movw   $0x720,(%eax)
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100511:	83 c0 02             	add    $0x2,%eax
f0100514:	39 d0                	cmp    %edx,%eax
f0100516:	75 f4                	jne    f010050c <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f0100518:	66 83 ab fc 19 00 00 	subw   $0x50,0x19fc(%ebx)
f010051f:	50 
f0100520:	e9 1f ff ff ff       	jmp    f0100444 <cons_putc+0x135>

f0100525 <serial_intr>:
{
f0100525:	e8 cf 01 00 00       	call   f01006f9 <__x86.get_pc_thunk.ax>
f010052a:	05 02 f4 07 00       	add    $0x7f402,%eax
	if (serial_exists)
f010052f:	80 b8 08 1a 00 00 00 	cmpb   $0x0,0x1a08(%eax)
f0100536:	75 01                	jne    f0100539 <serial_intr+0x14>
f0100538:	c3                   	ret    
{
f0100539:	55                   	push   %ebp
f010053a:	89 e5                	mov    %esp,%ebp
f010053c:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f010053f:	8d 80 3f 08 f8 ff    	lea    -0x7f7c1(%eax),%eax
f0100545:	e8 3b fc ff ff       	call   f0100185 <cons_intr>
}
f010054a:	c9                   	leave  
f010054b:	c3                   	ret    

f010054c <kbd_intr>:
{
f010054c:	55                   	push   %ebp
f010054d:	89 e5                	mov    %esp,%ebp
f010054f:	83 ec 08             	sub    $0x8,%esp
f0100552:	e8 a2 01 00 00       	call   f01006f9 <__x86.get_pc_thunk.ax>
f0100557:	05 d5 f3 07 00       	add    $0x7f3d5,%eax
	cons_intr(kbd_proc_data);
f010055c:	8d 80 bd 08 f8 ff    	lea    -0x7f743(%eax),%eax
f0100562:	e8 1e fc ff ff       	call   f0100185 <cons_intr>
}
f0100567:	c9                   	leave  
f0100568:	c3                   	ret    

f0100569 <cons_getc>:
{
f0100569:	55                   	push   %ebp
f010056a:	89 e5                	mov    %esp,%ebp
f010056c:	53                   	push   %ebx
f010056d:	83 ec 04             	sub    $0x4,%esp
f0100570:	e8 f2 fb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100575:	81 c3 b7 f3 07 00    	add    $0x7f3b7,%ebx
	serial_intr();
f010057b:	e8 a5 ff ff ff       	call   f0100525 <serial_intr>
	kbd_intr();
f0100580:	e8 c7 ff ff ff       	call   f010054c <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100585:	8b 83 f4 19 00 00    	mov    0x19f4(%ebx),%eax
	return 0;
f010058b:	ba 00 00 00 00       	mov    $0x0,%edx
	if (cons.rpos != cons.wpos) {
f0100590:	3b 83 f8 19 00 00    	cmp    0x19f8(%ebx),%eax
f0100596:	74 1e                	je     f01005b6 <cons_getc+0x4d>
		c = cons.buf[cons.rpos++];
f0100598:	8d 48 01             	lea    0x1(%eax),%ecx
f010059b:	0f b6 94 03 f4 17 00 	movzbl 0x17f4(%ebx,%eax,1),%edx
f01005a2:	00 
			cons.rpos = 0;
f01005a3:	3d ff 01 00 00       	cmp    $0x1ff,%eax
f01005a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ad:	0f 45 c1             	cmovne %ecx,%eax
f01005b0:	89 83 f4 19 00 00    	mov    %eax,0x19f4(%ebx)
}
f01005b6:	89 d0                	mov    %edx,%eax
f01005b8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01005bb:	c9                   	leave  
f01005bc:	c3                   	ret    

f01005bd <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005bd:	55                   	push   %ebp
f01005be:	89 e5                	mov    %esp,%ebp
f01005c0:	57                   	push   %edi
f01005c1:	56                   	push   %esi
f01005c2:	53                   	push   %ebx
f01005c3:	83 ec 1c             	sub    $0x1c,%esp
f01005c6:	e8 9c fb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01005cb:	81 c3 61 f3 07 00    	add    $0x7f361,%ebx
	was = *cp;
f01005d1:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01005d8:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005df:	5a a5 
	if (*cp != 0xA55A) {
f01005e1:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005e8:	b9 b4 03 00 00       	mov    $0x3b4,%ecx
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005ed:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
	if (*cp != 0xA55A) {
f01005f2:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005f6:	0f 84 ac 00 00 00    	je     f01006a8 <cons_init+0xeb>
		addr_6845 = MONO_BASE;
f01005fc:	89 8b 04 1a 00 00    	mov    %ecx,0x1a04(%ebx)
f0100602:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100607:	89 ca                	mov    %ecx,%edx
f0100609:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010060a:	8d 71 01             	lea    0x1(%ecx),%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010060d:	89 f2                	mov    %esi,%edx
f010060f:	ec                   	in     (%dx),%al
f0100610:	0f b6 c0             	movzbl %al,%eax
f0100613:	c1 e0 08             	shl    $0x8,%eax
f0100616:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100619:	b8 0f 00 00 00       	mov    $0xf,%eax
f010061e:	89 ca                	mov    %ecx,%edx
f0100620:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100621:	89 f2                	mov    %esi,%edx
f0100623:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100624:	89 bb 00 1a 00 00    	mov    %edi,0x1a00(%ebx)
	pos |= inb(addr_6845 + 1);
f010062a:	0f b6 c0             	movzbl %al,%eax
f010062d:	0b 45 e4             	or     -0x1c(%ebp),%eax
	crt_pos = pos;
f0100630:	66 89 83 fc 19 00 00 	mov    %ax,0x19fc(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100637:	b9 00 00 00 00       	mov    $0x0,%ecx
f010063c:	89 c8                	mov    %ecx,%eax
f010063e:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100643:	ee                   	out    %al,(%dx)
f0100644:	bf fb 03 00 00       	mov    $0x3fb,%edi
f0100649:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010064e:	89 fa                	mov    %edi,%edx
f0100650:	ee                   	out    %al,(%dx)
f0100651:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100656:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010065b:	ee                   	out    %al,(%dx)
f010065c:	be f9 03 00 00       	mov    $0x3f9,%esi
f0100661:	89 c8                	mov    %ecx,%eax
f0100663:	89 f2                	mov    %esi,%edx
f0100665:	ee                   	out    %al,(%dx)
f0100666:	b8 03 00 00 00       	mov    $0x3,%eax
f010066b:	89 fa                	mov    %edi,%edx
f010066d:	ee                   	out    %al,(%dx)
f010066e:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100673:	89 c8                	mov    %ecx,%eax
f0100675:	ee                   	out    %al,(%dx)
f0100676:	b8 01 00 00 00       	mov    $0x1,%eax
f010067b:	89 f2                	mov    %esi,%edx
f010067d:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010067e:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100683:	ec                   	in     (%dx),%al
f0100684:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100686:	3c ff                	cmp    $0xff,%al
f0100688:	0f 95 83 08 1a 00 00 	setne  0x1a08(%ebx)
f010068f:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100694:	ec                   	in     (%dx),%al
f0100695:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010069a:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010069b:	80 f9 ff             	cmp    $0xff,%cl
f010069e:	74 1e                	je     f01006be <cons_init+0x101>
		cprintf("Serial port does not exist!\n");
}
f01006a0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01006a3:	5b                   	pop    %ebx
f01006a4:	5e                   	pop    %esi
f01006a5:	5f                   	pop    %edi
f01006a6:	5d                   	pop    %ebp
f01006a7:	c3                   	ret    
		*cp = was;
f01006a8:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
f01006af:	b9 d4 03 00 00       	mov    $0x3d4,%ecx
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006b4:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
f01006b9:	e9 3e ff ff ff       	jmp    f01005fc <cons_init+0x3f>
		cprintf("Serial port does not exist!\n");
f01006be:	83 ec 0c             	sub    $0xc,%esp
f01006c1:	8d 83 cd 5a f8 ff    	lea    -0x7a533(%ebx),%eax
f01006c7:	50                   	push   %eax
f01006c8:	e8 48 32 00 00       	call   f0103915 <cprintf>
f01006cd:	83 c4 10             	add    $0x10,%esp
}
f01006d0:	eb ce                	jmp    f01006a0 <cons_init+0xe3>

f01006d2 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01006d2:	55                   	push   %ebp
f01006d3:	89 e5                	mov    %esp,%ebp
f01006d5:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01006d8:	8b 45 08             	mov    0x8(%ebp),%eax
f01006db:	e8 2f fc ff ff       	call   f010030f <cons_putc>
}
f01006e0:	c9                   	leave  
f01006e1:	c3                   	ret    

f01006e2 <getchar>:

int
getchar(void)
{
f01006e2:	55                   	push   %ebp
f01006e3:	89 e5                	mov    %esp,%ebp
f01006e5:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006e8:	e8 7c fe ff ff       	call   f0100569 <cons_getc>
f01006ed:	85 c0                	test   %eax,%eax
f01006ef:	74 f7                	je     f01006e8 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006f1:	c9                   	leave  
f01006f2:	c3                   	ret    

f01006f3 <iscons>:
int
iscons(int fdnum)
{
	// used by readline
	return 1;
}
f01006f3:	b8 01 00 00 00       	mov    $0x1,%eax
f01006f8:	c3                   	ret    

f01006f9 <__x86.get_pc_thunk.ax>:
f01006f9:	8b 04 24             	mov    (%esp),%eax
f01006fc:	c3                   	ret    

f01006fd <__x86.get_pc_thunk.si>:
f01006fd:	8b 34 24             	mov    (%esp),%esi
f0100700:	c3                   	ret    

f0100701 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100701:	55                   	push   %ebp
f0100702:	89 e5                	mov    %esp,%ebp
f0100704:	56                   	push   %esi
f0100705:	53                   	push   %ebx
f0100706:	e8 5c fa ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010070b:	81 c3 21 f2 07 00    	add    $0x7f221,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100711:	83 ec 04             	sub    $0x4,%esp
f0100714:	8d 83 f4 5c f8 ff    	lea    -0x7a30c(%ebx),%eax
f010071a:	50                   	push   %eax
f010071b:	8d 83 12 5d f8 ff    	lea    -0x7a2ee(%ebx),%eax
f0100721:	50                   	push   %eax
f0100722:	8d b3 17 5d f8 ff    	lea    -0x7a2e9(%ebx),%esi
f0100728:	56                   	push   %esi
f0100729:	e8 e7 31 00 00       	call   f0103915 <cprintf>
f010072e:	83 c4 0c             	add    $0xc,%esp
f0100731:	8d 83 ac 5d f8 ff    	lea    -0x7a254(%ebx),%eax
f0100737:	50                   	push   %eax
f0100738:	8d 83 20 5d f8 ff    	lea    -0x7a2e0(%ebx),%eax
f010073e:	50                   	push   %eax
f010073f:	56                   	push   %esi
f0100740:	e8 d0 31 00 00       	call   f0103915 <cprintf>
	return 0;
}
f0100745:	b8 00 00 00 00       	mov    $0x0,%eax
f010074a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010074d:	5b                   	pop    %ebx
f010074e:	5e                   	pop    %esi
f010074f:	5d                   	pop    %ebp
f0100750:	c3                   	ret    

f0100751 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100751:	55                   	push   %ebp
f0100752:	89 e5                	mov    %esp,%ebp
f0100754:	57                   	push   %edi
f0100755:	56                   	push   %esi
f0100756:	53                   	push   %ebx
f0100757:	83 ec 18             	sub    $0x18,%esp
f010075a:	e8 08 fa ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010075f:	81 c3 cd f1 07 00    	add    $0x7f1cd,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100765:	8d 83 29 5d f8 ff    	lea    -0x7a2d7(%ebx),%eax
f010076b:	50                   	push   %eax
f010076c:	e8 a4 31 00 00       	call   f0103915 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100771:	83 c4 08             	add    $0x8,%esp
f0100774:	ff b3 f8 ff ff ff    	push   -0x8(%ebx)
f010077a:	8d 83 d4 5d f8 ff    	lea    -0x7a22c(%ebx),%eax
f0100780:	50                   	push   %eax
f0100781:	e8 8f 31 00 00       	call   f0103915 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100786:	83 c4 0c             	add    $0xc,%esp
f0100789:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f010078f:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100795:	50                   	push   %eax
f0100796:	57                   	push   %edi
f0100797:	8d 83 fc 5d f8 ff    	lea    -0x7a204(%ebx),%eax
f010079d:	50                   	push   %eax
f010079e:	e8 72 31 00 00       	call   f0103915 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007a3:	83 c4 0c             	add    $0xc,%esp
f01007a6:	c7 c0 81 53 10 f0    	mov    $0xf0105381,%eax
f01007ac:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007b2:	52                   	push   %edx
f01007b3:	50                   	push   %eax
f01007b4:	8d 83 20 5e f8 ff    	lea    -0x7a1e0(%ebx),%eax
f01007ba:	50                   	push   %eax
f01007bb:	e8 55 31 00 00       	call   f0103915 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007c0:	83 c4 0c             	add    $0xc,%esp
f01007c3:	c7 c0 e0 10 18 f0    	mov    $0xf01810e0,%eax
f01007c9:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007cf:	52                   	push   %edx
f01007d0:	50                   	push   %eax
f01007d1:	8d 83 44 5e f8 ff    	lea    -0x7a1bc(%ebx),%eax
f01007d7:	50                   	push   %eax
f01007d8:	e8 38 31 00 00       	call   f0103915 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007dd:	83 c4 0c             	add    $0xc,%esp
f01007e0:	c7 c6 00 20 18 f0    	mov    $0xf0182000,%esi
f01007e6:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007ec:	50                   	push   %eax
f01007ed:	56                   	push   %esi
f01007ee:	8d 83 68 5e f8 ff    	lea    -0x7a198(%ebx),%eax
f01007f4:	50                   	push   %eax
f01007f5:	e8 1b 31 00 00       	call   f0103915 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007fa:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01007fd:	29 fe                	sub    %edi,%esi
f01007ff:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100805:	c1 fe 0a             	sar    $0xa,%esi
f0100808:	56                   	push   %esi
f0100809:	8d 83 8c 5e f8 ff    	lea    -0x7a174(%ebx),%eax
f010080f:	50                   	push   %eax
f0100810:	e8 00 31 00 00       	call   f0103915 <cprintf>
	return 0;
}
f0100815:	b8 00 00 00 00       	mov    $0x0,%eax
f010081a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010081d:	5b                   	pop    %ebx
f010081e:	5e                   	pop    %esi
f010081f:	5f                   	pop    %edi
f0100820:	5d                   	pop    %ebp
f0100821:	c3                   	ret    

f0100822 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100822:	55                   	push   %ebp
f0100823:	89 e5                	mov    %esp,%ebp
f0100825:	57                   	push   %edi
f0100826:	56                   	push   %esi
f0100827:	53                   	push   %ebx
f0100828:	83 ec 48             	sub    $0x48,%esp
f010082b:	e8 37 f9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100830:	81 c3 fc f0 07 00    	add    $0x7f0fc,%ebx
	// Your code here.
		cprintf ("Stack backtrace:\n");
f0100836:	8d 83 42 5d f8 ff    	lea    -0x7a2be(%ebx),%eax
f010083c:	50                   	push   %eax
f010083d:	e8 d3 30 00 00       	call   f0103915 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100842:	89 ee                	mov    %ebp,%esi
f0100844:	83 c4 10             	add    $0x10,%esp
        	args[0] = ((uint32_t *)ebp)[2];
        	args[1] = ((uint32_t *)ebp)[3];
        	args[2] = ((uint32_t *)ebp)[4];
        	args[3] = ((uint32_t *)ebp)[5];
        	args[4] = ((uint32_t *)ebp)[6];
        	cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n",
f0100847:	8d 83 b8 5e f8 ff    	lea    -0x7a148(%ebx),%eax
f010084d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
                	ebp, eip, args[0], args[1], args[2], args[3], args[4]);
                
        	debuginfo_eip (eip, &dbinfo);
        	cprintf("         %s:%d: %.*s+%d\n",
f0100850:	8d 83 54 5d f8 ff    	lea    -0x7a2ac(%ebx),%eax
f0100856:	89 45 c0             	mov    %eax,-0x40(%ebp)
        	eip = ((uint32_t *)ebp)[1];
f0100859:	8b 7e 04             	mov    0x4(%esi),%edi
        	cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n",
f010085c:	ff 76 18             	push   0x18(%esi)
f010085f:	ff 76 14             	push   0x14(%esi)
f0100862:	ff 76 10             	push   0x10(%esi)
f0100865:	ff 76 0c             	push   0xc(%esi)
f0100868:	ff 76 08             	push   0x8(%esi)
f010086b:	57                   	push   %edi
f010086c:	56                   	push   %esi
f010086d:	ff 75 c4             	push   -0x3c(%ebp)
f0100870:	e8 a0 30 00 00       	call   f0103915 <cprintf>
        	debuginfo_eip (eip, &dbinfo);
f0100875:	83 c4 18             	add    $0x18,%esp
f0100878:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010087b:	50                   	push   %eax
f010087c:	57                   	push   %edi
f010087d:	e8 b0 3b 00 00       	call   f0104432 <debuginfo_eip>
        	cprintf("         %s:%d: %.*s+%d\n",
f0100882:	83 c4 08             	add    $0x8,%esp
f0100885:	2b 7d e0             	sub    -0x20(%ebp),%edi
f0100888:	57                   	push   %edi
f0100889:	ff 75 d8             	push   -0x28(%ebp)
f010088c:	ff 75 dc             	push   -0x24(%ebp)
f010088f:	ff 75 d4             	push   -0x2c(%ebp)
f0100892:	ff 75 d0             	push   -0x30(%ebp)
f0100895:	ff 75 c0             	push   -0x40(%ebp)
f0100898:	e8 78 30 00 00       	call   f0103915 <cprintf>
                	dbinfo.eip_file, dbinfo.eip_line, dbinfo.eip_fn_namelen,
                	dbinfo.eip_fn_name, eip - dbinfo.eip_fn_addr);
                
        	ebp = *(uint32_t *)ebp;
f010089d:	8b 36                	mov    (%esi),%esi
    	} while (ebp);
f010089f:	83 c4 20             	add    $0x20,%esp
f01008a2:	85 f6                	test   %esi,%esi
f01008a4:	75 b3                	jne    f0100859 <mon_backtrace+0x37>

	return 0;
}
f01008a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01008ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008ae:	5b                   	pop    %ebx
f01008af:	5e                   	pop    %esi
f01008b0:	5f                   	pop    %edi
f01008b1:	5d                   	pop    %ebp
f01008b2:	c3                   	ret    

f01008b3 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008b3:	55                   	push   %ebp
f01008b4:	89 e5                	mov    %esp,%ebp
f01008b6:	57                   	push   %edi
f01008b7:	56                   	push   %esi
f01008b8:	53                   	push   %ebx
f01008b9:	83 ec 68             	sub    $0x68,%esp
f01008bc:	e8 a6 f8 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01008c1:	81 c3 6b f0 07 00    	add    $0x7f06b,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008c7:	8d 83 f0 5e f8 ff    	lea    -0x7a110(%ebx),%eax
f01008cd:	50                   	push   %eax
f01008ce:	e8 42 30 00 00       	call   f0103915 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008d3:	8d 83 14 5f f8 ff    	lea    -0x7a0ec(%ebx),%eax
f01008d9:	89 04 24             	mov    %eax,(%esp)
f01008dc:	e8 34 30 00 00       	call   f0103915 <cprintf>

	if (tf != NULL)
f01008e1:	83 c4 10             	add    $0x10,%esp
f01008e4:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01008e8:	74 0e                	je     f01008f8 <monitor+0x45>
		print_trapframe(tf);
f01008ea:	83 ec 0c             	sub    $0xc,%esp
f01008ed:	ff 75 08             	push   0x8(%ebp)
f01008f0:	e8 2e 35 00 00       	call   f0103e23 <print_trapframe>
f01008f5:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f01008f8:	8d bb 71 5d f8 ff    	lea    -0x7a28f(%ebx),%edi
f01008fe:	eb 4a                	jmp    f010094a <monitor+0x97>
f0100900:	83 ec 08             	sub    $0x8,%esp
f0100903:	0f be c0             	movsbl %al,%eax
f0100906:	50                   	push   %eax
f0100907:	57                   	push   %edi
f0100908:	e8 10 46 00 00       	call   f0104f1d <strchr>
f010090d:	83 c4 10             	add    $0x10,%esp
f0100910:	85 c0                	test   %eax,%eax
f0100912:	74 08                	je     f010091c <monitor+0x69>
			*buf++ = 0;
f0100914:	c6 06 00             	movb   $0x0,(%esi)
f0100917:	8d 76 01             	lea    0x1(%esi),%esi
f010091a:	eb 79                	jmp    f0100995 <monitor+0xe2>
		if (*buf == 0)
f010091c:	80 3e 00             	cmpb   $0x0,(%esi)
f010091f:	74 7f                	je     f01009a0 <monitor+0xed>
		if (argc == MAXARGS-1) {
f0100921:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f0100925:	74 0f                	je     f0100936 <monitor+0x83>
		argv[argc++] = buf;
f0100927:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f010092a:	8d 48 01             	lea    0x1(%eax),%ecx
f010092d:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f0100930:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100934:	eb 44                	jmp    f010097a <monitor+0xc7>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100936:	83 ec 08             	sub    $0x8,%esp
f0100939:	6a 10                	push   $0x10
f010093b:	8d 83 76 5d f8 ff    	lea    -0x7a28a(%ebx),%eax
f0100941:	50                   	push   %eax
f0100942:	e8 ce 2f 00 00       	call   f0103915 <cprintf>
			return 0;
f0100947:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f010094a:	8d 83 6d 5d f8 ff    	lea    -0x7a293(%ebx),%eax
f0100950:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100953:	83 ec 0c             	sub    $0xc,%esp
f0100956:	ff 75 a4             	push   -0x5c(%ebp)
f0100959:	e8 6e 43 00 00       	call   f0104ccc <readline>
f010095e:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100960:	83 c4 10             	add    $0x10,%esp
f0100963:	85 c0                	test   %eax,%eax
f0100965:	74 ec                	je     f0100953 <monitor+0xa0>
	argv[argc] = 0;
f0100967:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f010096e:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f0100975:	eb 1e                	jmp    f0100995 <monitor+0xe2>
			buf++;
f0100977:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010097a:	0f b6 06             	movzbl (%esi),%eax
f010097d:	84 c0                	test   %al,%al
f010097f:	74 14                	je     f0100995 <monitor+0xe2>
f0100981:	83 ec 08             	sub    $0x8,%esp
f0100984:	0f be c0             	movsbl %al,%eax
f0100987:	50                   	push   %eax
f0100988:	57                   	push   %edi
f0100989:	e8 8f 45 00 00       	call   f0104f1d <strchr>
f010098e:	83 c4 10             	add    $0x10,%esp
f0100991:	85 c0                	test   %eax,%eax
f0100993:	74 e2                	je     f0100977 <monitor+0xc4>
		while (*buf && strchr(WHITESPACE, *buf))
f0100995:	0f b6 06             	movzbl (%esi),%eax
f0100998:	84 c0                	test   %al,%al
f010099a:	0f 85 60 ff ff ff    	jne    f0100900 <monitor+0x4d>
	argv[argc] = 0;
f01009a0:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009a3:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f01009aa:	00 
	if (argc == 0)
f01009ab:	85 c0                	test   %eax,%eax
f01009ad:	74 9b                	je     f010094a <monitor+0x97>
		if (strcmp(argv[0], commands[i].name) == 0)
f01009af:	83 ec 08             	sub    $0x8,%esp
f01009b2:	8d 83 12 5d f8 ff    	lea    -0x7a2ee(%ebx),%eax
f01009b8:	50                   	push   %eax
f01009b9:	ff 75 a8             	push   -0x58(%ebp)
f01009bc:	e8 fc 44 00 00       	call   f0104ebd <strcmp>
f01009c1:	83 c4 10             	add    $0x10,%esp
f01009c4:	85 c0                	test   %eax,%eax
f01009c6:	74 38                	je     f0100a00 <monitor+0x14d>
f01009c8:	83 ec 08             	sub    $0x8,%esp
f01009cb:	8d 83 20 5d f8 ff    	lea    -0x7a2e0(%ebx),%eax
f01009d1:	50                   	push   %eax
f01009d2:	ff 75 a8             	push   -0x58(%ebp)
f01009d5:	e8 e3 44 00 00       	call   f0104ebd <strcmp>
f01009da:	83 c4 10             	add    $0x10,%esp
f01009dd:	85 c0                	test   %eax,%eax
f01009df:	74 1a                	je     f01009fb <monitor+0x148>
	cprintf("Unknown command '%s'\n", argv[0]);
f01009e1:	83 ec 08             	sub    $0x8,%esp
f01009e4:	ff 75 a8             	push   -0x58(%ebp)
f01009e7:	8d 83 93 5d f8 ff    	lea    -0x7a26d(%ebx),%eax
f01009ed:	50                   	push   %eax
f01009ee:	e8 22 2f 00 00       	call   f0103915 <cprintf>
	return 0;
f01009f3:	83 c4 10             	add    $0x10,%esp
f01009f6:	e9 4f ff ff ff       	jmp    f010094a <monitor+0x97>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009fb:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f0100a00:	83 ec 04             	sub    $0x4,%esp
f0100a03:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100a06:	ff 75 08             	push   0x8(%ebp)
f0100a09:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a0c:	52                   	push   %edx
f0100a0d:	ff 75 a4             	push   -0x5c(%ebp)
f0100a10:	ff 94 83 0c 17 00 00 	call   *0x170c(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100a17:	83 c4 10             	add    $0x10,%esp
f0100a1a:	85 c0                	test   %eax,%eax
f0100a1c:	0f 89 28 ff ff ff    	jns    f010094a <monitor+0x97>
				break;
	}
}
f0100a22:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a25:	5b                   	pop    %ebx
f0100a26:	5e                   	pop    %esi
f0100a27:	5f                   	pop    %edi
f0100a28:	5d                   	pop    %ebp
f0100a29:	c3                   	ret    

f0100a2a <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a2a:	55                   	push   %ebp
f0100a2b:	89 e5                	mov    %esp,%ebp
f0100a2d:	57                   	push   %edi
f0100a2e:	56                   	push   %esi
f0100a2f:	53                   	push   %ebx
f0100a30:	83 ec 18             	sub    $0x18,%esp
f0100a33:	e8 2f f7 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100a38:	81 c3 f4 ee 07 00    	add    $0x7eef4,%ebx
f0100a3e:	89 c6                	mov    %eax,%esi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a40:	50                   	push   %eax
f0100a41:	e8 48 2e 00 00       	call   f010388e <mc146818_read>
f0100a46:	89 c7                	mov    %eax,%edi
f0100a48:	83 c6 01             	add    $0x1,%esi
f0100a4b:	89 34 24             	mov    %esi,(%esp)
f0100a4e:	e8 3b 2e 00 00       	call   f010388e <mc146818_read>
f0100a53:	c1 e0 08             	shl    $0x8,%eax
f0100a56:	09 f8                	or     %edi,%eax
}
f0100a58:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a5b:	5b                   	pop    %ebx
f0100a5c:	5e                   	pop    %esi
f0100a5d:	5f                   	pop    %edi
f0100a5e:	5d                   	pop    %ebp
f0100a5f:	c3                   	ret    

f0100a60 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a60:	e8 06 27 00 00       	call   f010316b <__x86.get_pc_thunk.dx>
f0100a65:	81 c2 c7 ee 07 00    	add    $0x7eec7,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a6b:	83 ba 18 1a 00 00 00 	cmpl   $0x0,0x1a18(%edx)
f0100a72:	74 3d                	je     f0100ab1 <boot_alloc+0x51>
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n == 0) 
f0100a74:	85 c0                	test   %eax,%eax
f0100a76:	74 53                	je     f0100acb <boot_alloc+0x6b>
{
f0100a78:	55                   	push   %ebp
f0100a79:	89 e5                	mov    %esp,%ebp
f0100a7b:	53                   	push   %ebx
f0100a7c:	83 ec 04             	sub    $0x4,%esp
	{
		return nextfree;
	} 
	result = nextfree;
f0100a7f:	8b 8a 18 1a 00 00    	mov    0x1a18(%edx),%ecx
	nextfree = ROUNDUP(nextfree + n, PGSIZE);
f0100a85:	8d 9c 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%ebx
f0100a8c:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0100a92:	89 9a 18 1a 00 00    	mov    %ebx,0x1a18(%edx)
	if ((uint32_t)nextfree > KERNBASE + npages * PGSIZE) 
f0100a98:	8b 82 14 1a 00 00    	mov    0x1a14(%edx),%eax
f0100a9e:	05 00 00 0f 00       	add    $0xf0000,%eax
f0100aa3:	c1 e0 0c             	shl    $0xc,%eax
f0100aa6:	39 d8                	cmp    %ebx,%eax
f0100aa8:	72 2a                	jb     f0100ad4 <boot_alloc+0x74>
	{
		panic("Out of memory.\n");
	} 
	return result;
}
f0100aaa:	89 c8                	mov    %ecx,%eax
f0100aac:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100aaf:	c9                   	leave  
f0100ab0:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100ab1:	c7 c1 00 20 18 f0    	mov    $0xf0182000,%ecx
f0100ab7:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0100abd:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100ac3:	89 8a 18 1a 00 00    	mov    %ecx,0x1a18(%edx)
f0100ac9:	eb a9                	jmp    f0100a74 <boot_alloc+0x14>
		return nextfree;
f0100acb:	8b 8a 18 1a 00 00    	mov    0x1a18(%edx),%ecx
}
f0100ad1:	89 c8                	mov    %ecx,%eax
f0100ad3:	c3                   	ret    
		panic("Out of memory.\n");
f0100ad4:	83 ec 04             	sub    $0x4,%esp
f0100ad7:	8d 82 39 5f f8 ff    	lea    -0x7a0c7(%edx),%eax
f0100add:	50                   	push   %eax
f0100ade:	6a 72                	push   $0x72
f0100ae0:	8d 82 49 5f f8 ff    	lea    -0x7a0b7(%edx),%eax
f0100ae6:	50                   	push   %eax
f0100ae7:	89 d3                	mov    %edx,%ebx
f0100ae9:	e8 c3 f5 ff ff       	call   f01000b1 <_panic>

f0100aee <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100aee:	55                   	push   %ebp
f0100aef:	89 e5                	mov    %esp,%ebp
f0100af1:	53                   	push   %ebx
f0100af2:	83 ec 04             	sub    $0x4,%esp
f0100af5:	e8 75 26 00 00       	call   f010316f <__x86.get_pc_thunk.cx>
f0100afa:	81 c1 32 ee 07 00    	add    $0x7ee32,%ecx
f0100b00:	89 c3                	mov    %eax,%ebx
f0100b02:	89 d0                	mov    %edx,%eax
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b04:	c1 ea 16             	shr    $0x16,%edx
	if (!(*pgdir & PTE_P))
f0100b07:	8b 14 93             	mov    (%ebx,%edx,4),%edx
f0100b0a:	f6 c2 01             	test   $0x1,%dl
f0100b0d:	74 54                	je     f0100b63 <check_va2pa+0x75>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b0f:	89 d3                	mov    %edx,%ebx
f0100b11:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b17:	c1 ea 0c             	shr    $0xc,%edx
f0100b1a:	3b 91 14 1a 00 00    	cmp    0x1a14(%ecx),%edx
f0100b20:	73 26                	jae    f0100b48 <check_va2pa+0x5a>
	if (!(p[PTX(va)] & PTE_P))
f0100b22:	c1 e8 0c             	shr    $0xc,%eax
f0100b25:	25 ff 03 00 00       	and    $0x3ff,%eax
f0100b2a:	8b 94 83 00 00 00 f0 	mov    -0x10000000(%ebx,%eax,4),%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b31:	89 d0                	mov    %edx,%eax
f0100b33:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b38:	f6 c2 01             	test   $0x1,%dl
f0100b3b:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b40:	0f 44 c2             	cmove  %edx,%eax
}
f0100b43:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b46:	c9                   	leave  
f0100b47:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b48:	53                   	push   %ebx
f0100b49:	8d 81 3c 62 f8 ff    	lea    -0x79dc4(%ecx),%eax
f0100b4f:	50                   	push   %eax
f0100b50:	68 36 03 00 00       	push   $0x336
f0100b55:	8d 81 49 5f f8 ff    	lea    -0x7a0b7(%ecx),%eax
f0100b5b:	50                   	push   %eax
f0100b5c:	89 cb                	mov    %ecx,%ebx
f0100b5e:	e8 4e f5 ff ff       	call   f01000b1 <_panic>
		return ~0;
f0100b63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b68:	eb d9                	jmp    f0100b43 <check_va2pa+0x55>

f0100b6a <check_page_free_list>:
{
f0100b6a:	55                   	push   %ebp
f0100b6b:	89 e5                	mov    %esp,%ebp
f0100b6d:	57                   	push   %edi
f0100b6e:	56                   	push   %esi
f0100b6f:	53                   	push   %ebx
f0100b70:	83 ec 2c             	sub    $0x2c,%esp
f0100b73:	e8 fb 25 00 00       	call   f0103173 <__x86.get_pc_thunk.di>
f0100b78:	81 c7 b4 ed 07 00    	add    $0x7edb4,%edi
f0100b7e:	89 7d d4             	mov    %edi,-0x2c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b81:	84 c0                	test   %al,%al
f0100b83:	0f 85 dc 02 00 00    	jne    f0100e65 <check_page_free_list+0x2fb>
	if (!page_free_list)
f0100b89:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100b8c:	83 b8 20 1a 00 00 00 	cmpl   $0x0,0x1a20(%eax)
f0100b93:	74 0a                	je     f0100b9f <check_page_free_list+0x35>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b95:	bf 00 04 00 00       	mov    $0x400,%edi
f0100b9a:	e9 29 03 00 00       	jmp    f0100ec8 <check_page_free_list+0x35e>
		panic("'page_free_list' is a null pointer!");
f0100b9f:	83 ec 04             	sub    $0x4,%esp
f0100ba2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100ba5:	8d 83 60 62 f8 ff    	lea    -0x79da0(%ebx),%eax
f0100bab:	50                   	push   %eax
f0100bac:	68 72 02 00 00       	push   $0x272
f0100bb1:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0100bb7:	50                   	push   %eax
f0100bb8:	e8 f4 f4 ff ff       	call   f01000b1 <_panic>
f0100bbd:	50                   	push   %eax
f0100bbe:	89 cb                	mov    %ecx,%ebx
f0100bc0:	8d 81 3c 62 f8 ff    	lea    -0x79dc4(%ecx),%eax
f0100bc6:	50                   	push   %eax
f0100bc7:	6a 56                	push   $0x56
f0100bc9:	8d 81 55 5f f8 ff    	lea    -0x7a0ab(%ecx),%eax
f0100bcf:	50                   	push   %eax
f0100bd0:	e8 dc f4 ff ff       	call   f01000b1 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bd5:	8b 36                	mov    (%esi),%esi
f0100bd7:	85 f6                	test   %esi,%esi
f0100bd9:	74 47                	je     f0100c22 <check_page_free_list+0xb8>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bdb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100bde:	89 f0                	mov    %esi,%eax
f0100be0:	2b 81 0c 1a 00 00    	sub    0x1a0c(%ecx),%eax
f0100be6:	c1 f8 03             	sar    $0x3,%eax
f0100be9:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100bec:	89 c2                	mov    %eax,%edx
f0100bee:	c1 ea 16             	shr    $0x16,%edx
f0100bf1:	39 fa                	cmp    %edi,%edx
f0100bf3:	73 e0                	jae    f0100bd5 <check_page_free_list+0x6b>
	if (PGNUM(pa) >= npages)
f0100bf5:	89 c2                	mov    %eax,%edx
f0100bf7:	c1 ea 0c             	shr    $0xc,%edx
f0100bfa:	3b 91 14 1a 00 00    	cmp    0x1a14(%ecx),%edx
f0100c00:	73 bb                	jae    f0100bbd <check_page_free_list+0x53>
			memset(page2kva(pp), 0x97, 128);
f0100c02:	83 ec 04             	sub    $0x4,%esp
f0100c05:	68 80 00 00 00       	push   $0x80
f0100c0a:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100c0f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c14:	50                   	push   %eax
f0100c15:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c18:	e8 3f 43 00 00       	call   f0104f5c <memset>
f0100c1d:	83 c4 10             	add    $0x10,%esp
f0100c20:	eb b3                	jmp    f0100bd5 <check_page_free_list+0x6b>
	first_free_page = (char *) boot_alloc(0);
f0100c22:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c27:	e8 34 fe ff ff       	call   f0100a60 <boot_alloc>
f0100c2c:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c2f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c32:	8b 90 20 1a 00 00    	mov    0x1a20(%eax),%edx
		assert(pp >= pages);
f0100c38:	8b 88 0c 1a 00 00    	mov    0x1a0c(%eax),%ecx
		assert(pp < pages + npages);
f0100c3e:	8b 80 14 1a 00 00    	mov    0x1a14(%eax),%eax
f0100c44:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100c47:	8d 34 c1             	lea    (%ecx,%eax,8),%esi
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c4a:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c4f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c54:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c57:	e9 07 01 00 00       	jmp    f0100d63 <check_page_free_list+0x1f9>
		assert(pp >= pages);
f0100c5c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c5f:	8d 83 63 5f f8 ff    	lea    -0x7a09d(%ebx),%eax
f0100c65:	50                   	push   %eax
f0100c66:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0100c6c:	50                   	push   %eax
f0100c6d:	68 8c 02 00 00       	push   $0x28c
f0100c72:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0100c78:	50                   	push   %eax
f0100c79:	e8 33 f4 ff ff       	call   f01000b1 <_panic>
		assert(pp < pages + npages);
f0100c7e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c81:	8d 83 84 5f f8 ff    	lea    -0x7a07c(%ebx),%eax
f0100c87:	50                   	push   %eax
f0100c88:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0100c8e:	50                   	push   %eax
f0100c8f:	68 8d 02 00 00       	push   $0x28d
f0100c94:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0100c9a:	50                   	push   %eax
f0100c9b:	e8 11 f4 ff ff       	call   f01000b1 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ca0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100ca3:	8d 83 84 62 f8 ff    	lea    -0x79d7c(%ebx),%eax
f0100ca9:	50                   	push   %eax
f0100caa:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0100cb0:	50                   	push   %eax
f0100cb1:	68 8e 02 00 00       	push   $0x28e
f0100cb6:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0100cbc:	50                   	push   %eax
f0100cbd:	e8 ef f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != 0);
f0100cc2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100cc5:	8d 83 98 5f f8 ff    	lea    -0x7a068(%ebx),%eax
f0100ccb:	50                   	push   %eax
f0100ccc:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0100cd2:	50                   	push   %eax
f0100cd3:	68 91 02 00 00       	push   $0x291
f0100cd8:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0100cde:	50                   	push   %eax
f0100cdf:	e8 cd f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ce4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100ce7:	8d 83 a9 5f f8 ff    	lea    -0x7a057(%ebx),%eax
f0100ced:	50                   	push   %eax
f0100cee:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0100cf4:	50                   	push   %eax
f0100cf5:	68 92 02 00 00       	push   $0x292
f0100cfa:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0100d00:	50                   	push   %eax
f0100d01:	e8 ab f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d06:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d09:	8d 83 b8 62 f8 ff    	lea    -0x79d48(%ebx),%eax
f0100d0f:	50                   	push   %eax
f0100d10:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0100d16:	50                   	push   %eax
f0100d17:	68 93 02 00 00       	push   $0x293
f0100d1c:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0100d22:	50                   	push   %eax
f0100d23:	e8 89 f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d28:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d2b:	8d 83 c2 5f f8 ff    	lea    -0x7a03e(%ebx),%eax
f0100d31:	50                   	push   %eax
f0100d32:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0100d38:	50                   	push   %eax
f0100d39:	68 94 02 00 00       	push   $0x294
f0100d3e:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0100d44:	50                   	push   %eax
f0100d45:	e8 67 f3 ff ff       	call   f01000b1 <_panic>
	if (PGNUM(pa) >= npages)
f0100d4a:	89 c3                	mov    %eax,%ebx
f0100d4c:	c1 eb 0c             	shr    $0xc,%ebx
f0100d4f:	39 5d cc             	cmp    %ebx,-0x34(%ebp)
f0100d52:	76 6d                	jbe    f0100dc1 <check_page_free_list+0x257>
	return (void *)(pa + KERNBASE);
f0100d54:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d59:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d5c:	77 7c                	ja     f0100dda <check_page_free_list+0x270>
			++nfree_extmem;
f0100d5e:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d61:	8b 12                	mov    (%edx),%edx
f0100d63:	85 d2                	test   %edx,%edx
f0100d65:	0f 84 91 00 00 00    	je     f0100dfc <check_page_free_list+0x292>
		assert(pp >= pages);
f0100d6b:	39 d1                	cmp    %edx,%ecx
f0100d6d:	0f 87 e9 fe ff ff    	ja     f0100c5c <check_page_free_list+0xf2>
		assert(pp < pages + npages);
f0100d73:	39 d6                	cmp    %edx,%esi
f0100d75:	0f 86 03 ff ff ff    	jbe    f0100c7e <check_page_free_list+0x114>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d7b:	89 d0                	mov    %edx,%eax
f0100d7d:	29 c8                	sub    %ecx,%eax
f0100d7f:	a8 07                	test   $0x7,%al
f0100d81:	0f 85 19 ff ff ff    	jne    f0100ca0 <check_page_free_list+0x136>
	return (pp - pages) << PGSHIFT;
f0100d87:	c1 f8 03             	sar    $0x3,%eax
		assert(page2pa(pp) != 0);
f0100d8a:	c1 e0 0c             	shl    $0xc,%eax
f0100d8d:	0f 84 2f ff ff ff    	je     f0100cc2 <check_page_free_list+0x158>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d93:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100d98:	0f 84 46 ff ff ff    	je     f0100ce4 <check_page_free_list+0x17a>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d9e:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100da3:	0f 84 5d ff ff ff    	je     f0100d06 <check_page_free_list+0x19c>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100da9:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100dae:	0f 84 74 ff ff ff    	je     f0100d28 <check_page_free_list+0x1be>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100db4:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100db9:	77 8f                	ja     f0100d4a <check_page_free_list+0x1e0>
			++nfree_basemem;
f0100dbb:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
f0100dbf:	eb a0                	jmp    f0100d61 <check_page_free_list+0x1f7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dc1:	50                   	push   %eax
f0100dc2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100dc5:	8d 83 3c 62 f8 ff    	lea    -0x79dc4(%ebx),%eax
f0100dcb:	50                   	push   %eax
f0100dcc:	6a 56                	push   $0x56
f0100dce:	8d 83 55 5f f8 ff    	lea    -0x7a0ab(%ebx),%eax
f0100dd4:	50                   	push   %eax
f0100dd5:	e8 d7 f2 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100dda:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100ddd:	8d 83 dc 62 f8 ff    	lea    -0x79d24(%ebx),%eax
f0100de3:	50                   	push   %eax
f0100de4:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0100dea:	50                   	push   %eax
f0100deb:	68 95 02 00 00       	push   $0x295
f0100df0:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0100df6:	50                   	push   %eax
f0100df7:	e8 b5 f2 ff ff       	call   f01000b1 <_panic>
	assert(nfree_basemem > 0);
f0100dfc:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0100dff:	85 db                	test   %ebx,%ebx
f0100e01:	7e 1e                	jle    f0100e21 <check_page_free_list+0x2b7>
	assert(nfree_extmem > 0);
f0100e03:	85 ff                	test   %edi,%edi
f0100e05:	7e 3c                	jle    f0100e43 <check_page_free_list+0x2d9>
	cprintf("check_page_free_list() succeeded!\n");
f0100e07:	83 ec 0c             	sub    $0xc,%esp
f0100e0a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100e0d:	8d 83 24 63 f8 ff    	lea    -0x79cdc(%ebx),%eax
f0100e13:	50                   	push   %eax
f0100e14:	e8 fc 2a 00 00       	call   f0103915 <cprintf>
}
f0100e19:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e1c:	5b                   	pop    %ebx
f0100e1d:	5e                   	pop    %esi
f0100e1e:	5f                   	pop    %edi
f0100e1f:	5d                   	pop    %ebp
f0100e20:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e21:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100e24:	8d 83 dc 5f f8 ff    	lea    -0x7a024(%ebx),%eax
f0100e2a:	50                   	push   %eax
f0100e2b:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0100e31:	50                   	push   %eax
f0100e32:	68 9d 02 00 00       	push   $0x29d
f0100e37:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0100e3d:	50                   	push   %eax
f0100e3e:	e8 6e f2 ff ff       	call   f01000b1 <_panic>
	assert(nfree_extmem > 0);
f0100e43:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100e46:	8d 83 ee 5f f8 ff    	lea    -0x7a012(%ebx),%eax
f0100e4c:	50                   	push   %eax
f0100e4d:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0100e53:	50                   	push   %eax
f0100e54:	68 9e 02 00 00       	push   $0x29e
f0100e59:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0100e5f:	50                   	push   %eax
f0100e60:	e8 4c f2 ff ff       	call   f01000b1 <_panic>
	if (!page_free_list)
f0100e65:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e68:	8b 80 20 1a 00 00    	mov    0x1a20(%eax),%eax
f0100e6e:	85 c0                	test   %eax,%eax
f0100e70:	0f 84 29 fd ff ff    	je     f0100b9f <check_page_free_list+0x35>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100e76:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100e79:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e7c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e7f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100e82:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100e85:	89 c2                	mov    %eax,%edx
f0100e87:	2b 97 0c 1a 00 00    	sub    0x1a0c(%edi),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100e8d:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100e93:	0f 95 c2             	setne  %dl
f0100e96:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100e99:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100e9d:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100e9f:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ea3:	8b 00                	mov    (%eax),%eax
f0100ea5:	85 c0                	test   %eax,%eax
f0100ea7:	75 d9                	jne    f0100e82 <check_page_free_list+0x318>
		*tp[1] = 0;
f0100ea9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100eac:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100eb2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100eb5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100eb8:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100eba:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ebd:	89 87 20 1a 00 00    	mov    %eax,0x1a20(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ec3:	bf 01 00 00 00       	mov    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ec8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ecb:	8b b0 20 1a 00 00    	mov    0x1a20(%eax),%esi
f0100ed1:	e9 01 fd ff ff       	jmp    f0100bd7 <check_page_free_list+0x6d>

f0100ed6 <page_init>:
{
f0100ed6:	55                   	push   %ebp
f0100ed7:	89 e5                	mov    %esp,%ebp
f0100ed9:	57                   	push   %edi
f0100eda:	56                   	push   %esi
f0100edb:	53                   	push   %ebx
f0100edc:	83 ec 0c             	sub    $0xc,%esp
f0100edf:	e8 19 f8 ff ff       	call   f01006fd <__x86.get_pc_thunk.si>
f0100ee4:	81 c6 48 ea 07 00    	add    $0x7ea48,%esi
	pages[0].pp_ref = 1;
f0100eea:	8b 86 0c 1a 00 00    	mov    0x1a0c(%esi),%eax
f0100ef0:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;
f0100ef6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	for (i = 1; i < npages; i++) 
f0100efc:	bf 08 00 00 00       	mov    $0x8,%edi
f0100f01:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100f06:	eb 32                	jmp    f0100f3a <page_init+0x64>
		} else if (i >= EXTPHYSMEM / PGSIZE && i < ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE) 
f0100f08:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100f0e:	77 53                	ja     f0100f63 <page_init+0x8d>
			pages[i].pp_ref = 0;
f0100f10:	89 f8                	mov    %edi,%eax
f0100f12:	03 86 0c 1a 00 00    	add    0x1a0c(%esi),%eax
f0100f18:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100f1e:	8b 96 20 1a 00 00    	mov    0x1a20(%esi),%edx
f0100f24:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100f26:	89 f8                	mov    %edi,%eax
f0100f28:	03 86 0c 1a 00 00    	add    0x1a0c(%esi),%eax
f0100f2e:	89 86 20 1a 00 00    	mov    %eax,0x1a20(%esi)
	for (i = 1; i < npages; i++) 
f0100f34:	83 c3 01             	add    $0x1,%ebx
f0100f37:	83 c7 08             	add    $0x8,%edi
f0100f3a:	39 9e 14 1a 00 00    	cmp    %ebx,0x1a14(%esi)
f0100f40:	76 4d                	jbe    f0100f8f <page_init+0xb9>
		if (i >= IOPHYSMEM / PGSIZE && i < EXTPHYSMEM / PGSIZE) 
f0100f42:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100f48:	83 f8 5f             	cmp    $0x5f,%eax
f0100f4b:	77 bb                	ja     f0100f08 <page_init+0x32>
			pages[i].pp_ref = 1;
f0100f4d:	89 f8                	mov    %edi,%eax
f0100f4f:	03 86 0c 1a 00 00    	add    0x1a0c(%esi),%eax
f0100f55:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100f5b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100f61:	eb d1                	jmp    f0100f34 <page_init+0x5e>
		} else if (i >= EXTPHYSMEM / PGSIZE && i < ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE) 
f0100f63:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f68:	e8 f3 fa ff ff       	call   f0100a60 <boot_alloc>
f0100f6d:	05 00 00 00 10       	add    $0x10000000,%eax
f0100f72:	c1 e8 0c             	shr    $0xc,%eax
f0100f75:	39 d8                	cmp    %ebx,%eax
f0100f77:	76 97                	jbe    f0100f10 <page_init+0x3a>
			pages[i].pp_ref = 1;
f0100f79:	89 f8                	mov    %edi,%eax
f0100f7b:	03 86 0c 1a 00 00    	add    0x1a0c(%esi),%eax
f0100f81:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100f87:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100f8d:	eb a5                	jmp    f0100f34 <page_init+0x5e>
}
f0100f8f:	83 c4 0c             	add    $0xc,%esp
f0100f92:	5b                   	pop    %ebx
f0100f93:	5e                   	pop    %esi
f0100f94:	5f                   	pop    %edi
f0100f95:	5d                   	pop    %ebp
f0100f96:	c3                   	ret    

f0100f97 <page_alloc>:
{
f0100f97:	55                   	push   %ebp
f0100f98:	89 e5                	mov    %esp,%ebp
f0100f9a:	56                   	push   %esi
f0100f9b:	53                   	push   %ebx
f0100f9c:	e8 c6 f1 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100fa1:	81 c3 8b e9 07 00    	add    $0x7e98b,%ebx
	if (page_free_list == NULL) 
f0100fa7:	8b b3 20 1a 00 00    	mov    0x1a20(%ebx),%esi
f0100fad:	85 f6                	test   %esi,%esi
f0100faf:	74 14                	je     f0100fc5 <page_alloc+0x2e>
	page_free_list = page_free_list->pp_link;
f0100fb1:	8b 06                	mov    (%esi),%eax
f0100fb3:	89 83 20 1a 00 00    	mov    %eax,0x1a20(%ebx)
	page->pp_link = NULL;
f0100fb9:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if (alloc_flags & ALLOC_ZERO) 
f0100fbf:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100fc3:	75 09                	jne    f0100fce <page_alloc+0x37>
}
f0100fc5:	89 f0                	mov    %esi,%eax
f0100fc7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100fca:	5b                   	pop    %ebx
f0100fcb:	5e                   	pop    %esi
f0100fcc:	5d                   	pop    %ebp
f0100fcd:	c3                   	ret    
f0100fce:	89 f0                	mov    %esi,%eax
f0100fd0:	2b 83 0c 1a 00 00    	sub    0x1a0c(%ebx),%eax
f0100fd6:	c1 f8 03             	sar    $0x3,%eax
f0100fd9:	89 c2                	mov    %eax,%edx
f0100fdb:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0100fde:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0100fe3:	3b 83 14 1a 00 00    	cmp    0x1a14(%ebx),%eax
f0100fe9:	73 1b                	jae    f0101006 <page_alloc+0x6f>
		memset(page2kva(page), 0, PGSIZE);
f0100feb:	83 ec 04             	sub    $0x4,%esp
f0100fee:	68 00 10 00 00       	push   $0x1000
f0100ff3:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100ff5:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0100ffb:	52                   	push   %edx
f0100ffc:	e8 5b 3f 00 00       	call   f0104f5c <memset>
f0101001:	83 c4 10             	add    $0x10,%esp
f0101004:	eb bf                	jmp    f0100fc5 <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101006:	52                   	push   %edx
f0101007:	8d 83 3c 62 f8 ff    	lea    -0x79dc4(%ebx),%eax
f010100d:	50                   	push   %eax
f010100e:	6a 56                	push   $0x56
f0101010:	8d 83 55 5f f8 ff    	lea    -0x7a0ab(%ebx),%eax
f0101016:	50                   	push   %eax
f0101017:	e8 95 f0 ff ff       	call   f01000b1 <_panic>

f010101c <page_free>:
{
f010101c:	55                   	push   %ebp
f010101d:	89 e5                	mov    %esp,%ebp
f010101f:	e8 d5 f6 ff ff       	call   f01006f9 <__x86.get_pc_thunk.ax>
f0101024:	05 08 e9 07 00       	add    $0x7e908,%eax
f0101029:	8b 55 08             	mov    0x8(%ebp),%edx
	pp->pp_link = page_free_list;
f010102c:	8b 88 20 1a 00 00    	mov    0x1a20(%eax),%ecx
f0101032:	89 0a                	mov    %ecx,(%edx)
	page_free_list = pp;
f0101034:	89 90 20 1a 00 00    	mov    %edx,0x1a20(%eax)
}
f010103a:	5d                   	pop    %ebp
f010103b:	c3                   	ret    

f010103c <page_decref>:
{
f010103c:	55                   	push   %ebp
f010103d:	89 e5                	mov    %esp,%ebp
f010103f:	83 ec 08             	sub    $0x8,%esp
f0101042:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101045:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101049:	83 e8 01             	sub    $0x1,%eax
f010104c:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101050:	66 85 c0             	test   %ax,%ax
f0101053:	74 02                	je     f0101057 <page_decref+0x1b>
}
f0101055:	c9                   	leave  
f0101056:	c3                   	ret    
		page_free(pp);
f0101057:	83 ec 0c             	sub    $0xc,%esp
f010105a:	52                   	push   %edx
f010105b:	e8 bc ff ff ff       	call   f010101c <page_free>
f0101060:	83 c4 10             	add    $0x10,%esp
}
f0101063:	eb f0                	jmp    f0101055 <page_decref+0x19>

f0101065 <pgdir_walk>:
{
f0101065:	55                   	push   %ebp
f0101066:	89 e5                	mov    %esp,%ebp
f0101068:	57                   	push   %edi
f0101069:	56                   	push   %esi
f010106a:	53                   	push   %ebx
f010106b:	83 ec 0c             	sub    $0xc,%esp
f010106e:	e8 00 21 00 00       	call   f0103173 <__x86.get_pc_thunk.di>
f0101073:	81 c7 b9 e8 07 00    	add    $0x7e8b9,%edi
f0101079:	8b 75 0c             	mov    0xc(%ebp),%esi
	uintptr_t* pt_addr = pgdir + PDX(va);
f010107c:	89 f3                	mov    %esi,%ebx
f010107e:	c1 eb 16             	shr    $0x16,%ebx
f0101081:	c1 e3 02             	shl    $0x2,%ebx
f0101084:	03 5d 08             	add    0x8(%ebp),%ebx
	if (*pt_addr & PTE_P) 
f0101087:	8b 03                	mov    (%ebx),%eax
f0101089:	a8 01                	test   $0x1,%al
f010108b:	75 58                	jne    f01010e5 <pgdir_walk+0x80>
	if (create == false) 
f010108d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101091:	0f 84 a9 00 00 00    	je     f0101140 <pgdir_walk+0xdb>
	struct PageInfo* new_pg = page_alloc(ALLOC_ZERO);
f0101097:	83 ec 0c             	sub    $0xc,%esp
f010109a:	6a 01                	push   $0x1
f010109c:	e8 f6 fe ff ff       	call   f0100f97 <page_alloc>
	if (new_pg == NULL) 
f01010a1:	83 c4 10             	add    $0x10,%esp
f01010a4:	85 c0                	test   %eax,%eax
f01010a6:	74 35                	je     f01010dd <pgdir_walk+0x78>
	new_pg->pp_ref ++;
f01010a8:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f01010ad:	2b 87 0c 1a 00 00    	sub    0x1a0c(%edi),%eax
f01010b3:	c1 f8 03             	sar    $0x3,%eax
f01010b6:	c1 e0 0c             	shl    $0xc,%eax
	*pt_addr = page2pa(new_pg) | PTE_U | PTE_W | PTE_P;
f01010b9:	89 c2                	mov    %eax,%edx
f01010bb:	83 ca 07             	or     $0x7,%edx
f01010be:	89 13                	mov    %edx,(%ebx)
	if (PGNUM(pa) >= npages)
f01010c0:	89 c2                	mov    %eax,%edx
f01010c2:	c1 ea 0c             	shr    $0xc,%edx
f01010c5:	3b 97 14 1a 00 00    	cmp    0x1a14(%edi),%edx
f01010cb:	73 58                	jae    f0101125 <pgdir_walk+0xc0>
	return (pte_t *)KADDR(PTE_ADDR(*pt_addr)) + PTX(va);
f01010cd:	c1 ee 0a             	shr    $0xa,%esi
f01010d0:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01010d6:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
}
f01010dd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010e0:	5b                   	pop    %ebx
f01010e1:	5e                   	pop    %esi
f01010e2:	5f                   	pop    %edi
f01010e3:	5d                   	pop    %ebp
f01010e4:	c3                   	ret    
		return (pte_t*)KADDR(PTE_ADDR(*pt_addr)) + PTX(va);
f01010e5:	89 c2                	mov    %eax,%edx
f01010e7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01010ed:	c1 e8 0c             	shr    $0xc,%eax
f01010f0:	3b 87 14 1a 00 00    	cmp    0x1a14(%edi),%eax
f01010f6:	73 12                	jae    f010110a <pgdir_walk+0xa5>
f01010f8:	c1 ee 0a             	shr    $0xa,%esi
f01010fb:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101101:	8d 84 32 00 00 00 f0 	lea    -0x10000000(%edx,%esi,1),%eax
f0101108:	eb d3                	jmp    f01010dd <pgdir_walk+0x78>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010110a:	52                   	push   %edx
f010110b:	8d 87 3c 62 f8 ff    	lea    -0x79dc4(%edi),%eax
f0101111:	50                   	push   %eax
f0101112:	68 84 01 00 00       	push   $0x184
f0101117:	8d 87 49 5f f8 ff    	lea    -0x7a0b7(%edi),%eax
f010111d:	50                   	push   %eax
f010111e:	89 fb                	mov    %edi,%ebx
f0101120:	e8 8c ef ff ff       	call   f01000b1 <_panic>
f0101125:	50                   	push   %eax
f0101126:	8d 87 3c 62 f8 ff    	lea    -0x79dc4(%edi),%eax
f010112c:	50                   	push   %eax
f010112d:	68 95 01 00 00       	push   $0x195
f0101132:	8d 87 49 5f f8 ff    	lea    -0x7a0b7(%edi),%eax
f0101138:	50                   	push   %eax
f0101139:	89 fb                	mov    %edi,%ebx
f010113b:	e8 71 ef ff ff       	call   f01000b1 <_panic>
		return NULL;
f0101140:	b8 00 00 00 00       	mov    $0x0,%eax
f0101145:	eb 96                	jmp    f01010dd <pgdir_walk+0x78>

f0101147 <boot_map_region>:
{
f0101147:	55                   	push   %ebp
f0101148:	89 e5                	mov    %esp,%ebp
f010114a:	57                   	push   %edi
f010114b:	56                   	push   %esi
f010114c:	53                   	push   %ebx
f010114d:	83 ec 1c             	sub    $0x1c,%esp
f0101150:	e8 1e 20 00 00       	call   f0103173 <__x86.get_pc_thunk.di>
f0101155:	81 c7 d7 e7 07 00    	add    $0x7e7d7,%edi
f010115b:	89 7d e0             	mov    %edi,-0x20(%ebp)
f010115e:	89 c7                	mov    %eax,%edi
f0101160:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101163:	89 ce                	mov    %ecx,%esi
	for (size_t i = 0; i < size; i += PGSIZE) 
f0101165:	bb 00 00 00 00       	mov    $0x0,%ebx
f010116a:	39 f3                	cmp    %esi,%ebx
f010116c:	73 4d                	jae    f01011bb <boot_map_region+0x74>
		p = pgdir_walk(pgdir, (void*)(va + i), 1);
f010116e:	83 ec 04             	sub    $0x4,%esp
f0101171:	6a 01                	push   $0x1
f0101173:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101176:	01 d8                	add    %ebx,%eax
f0101178:	50                   	push   %eax
f0101179:	57                   	push   %edi
f010117a:	e8 e6 fe ff ff       	call   f0101065 <pgdir_walk>
f010117f:	89 c2                	mov    %eax,%edx
		if (p == NULL) 
f0101181:	83 c4 10             	add    $0x10,%esp
f0101184:	85 c0                	test   %eax,%eax
f0101186:	74 15                	je     f010119d <boot_map_region+0x56>
		*p = (pa + i) | perm | PTE_P;
f0101188:	89 d8                	mov    %ebx,%eax
f010118a:	03 45 08             	add    0x8(%ebp),%eax
f010118d:	0b 45 0c             	or     0xc(%ebp),%eax
f0101190:	83 c8 01             	or     $0x1,%eax
f0101193:	89 02                	mov    %eax,(%edx)
	for (size_t i = 0; i < size; i += PGSIZE) 
f0101195:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010119b:	eb cd                	jmp    f010116a <boot_map_region+0x23>
			panic("Mapping failed\n");
f010119d:	83 ec 04             	sub    $0x4,%esp
f01011a0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01011a3:	8d 83 ff 5f f8 ff    	lea    -0x7a001(%ebx),%eax
f01011a9:	50                   	push   %eax
f01011aa:	68 ae 01 00 00       	push   $0x1ae
f01011af:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01011b5:	50                   	push   %eax
f01011b6:	e8 f6 ee ff ff       	call   f01000b1 <_panic>
}
f01011bb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011be:	5b                   	pop    %ebx
f01011bf:	5e                   	pop    %esi
f01011c0:	5f                   	pop    %edi
f01011c1:	5d                   	pop    %ebp
f01011c2:	c3                   	ret    

f01011c3 <page_lookup>:
{
f01011c3:	55                   	push   %ebp
f01011c4:	89 e5                	mov    %esp,%ebp
f01011c6:	56                   	push   %esi
f01011c7:	53                   	push   %ebx
f01011c8:	e8 9a ef ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01011cd:	81 c3 5f e7 07 00    	add    $0x7e75f,%ebx
f01011d3:	8b 75 10             	mov    0x10(%ebp),%esi
	uintptr_t* p = pgdir_walk(pgdir, va, 0);
f01011d6:	83 ec 04             	sub    $0x4,%esp
f01011d9:	6a 00                	push   $0x0
f01011db:	ff 75 0c             	push   0xc(%ebp)
f01011de:	ff 75 08             	push   0x8(%ebp)
f01011e1:	e8 7f fe ff ff       	call   f0101065 <pgdir_walk>
	if (p == NULL || (*p & PTE_P) == 0) 
f01011e6:	83 c4 10             	add    $0x10,%esp
f01011e9:	85 c0                	test   %eax,%eax
f01011eb:	74 21                	je     f010120e <page_lookup+0x4b>
f01011ed:	f6 00 01             	testb  $0x1,(%eax)
f01011f0:	74 3b                	je     f010122d <page_lookup+0x6a>
	if (pte_store != 0) 
f01011f2:	85 f6                	test   %esi,%esi
f01011f4:	74 02                	je     f01011f8 <page_lookup+0x35>
		*pte_store = p;
f01011f6:	89 06                	mov    %eax,(%esi)
f01011f8:	8b 00                	mov    (%eax),%eax
f01011fa:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011fd:	39 83 14 1a 00 00    	cmp    %eax,0x1a14(%ebx)
f0101203:	76 10                	jbe    f0101215 <page_lookup+0x52>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f0101205:	8b 93 0c 1a 00 00    	mov    0x1a0c(%ebx),%edx
f010120b:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f010120e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101211:	5b                   	pop    %ebx
f0101212:	5e                   	pop    %esi
f0101213:	5d                   	pop    %ebp
f0101214:	c3                   	ret    
		panic("pa2page called with invalid pa");
f0101215:	83 ec 04             	sub    $0x4,%esp
f0101218:	8d 83 48 63 f8 ff    	lea    -0x79cb8(%ebx),%eax
f010121e:	50                   	push   %eax
f010121f:	6a 4f                	push   $0x4f
f0101221:	8d 83 55 5f f8 ff    	lea    -0x7a0ab(%ebx),%eax
f0101227:	50                   	push   %eax
f0101228:	e8 84 ee ff ff       	call   f01000b1 <_panic>
		return NULL;
f010122d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101232:	eb da                	jmp    f010120e <page_lookup+0x4b>

f0101234 <page_remove>:
{
f0101234:	55                   	push   %ebp
f0101235:	89 e5                	mov    %esp,%ebp
f0101237:	53                   	push   %ebx
f0101238:	83 ec 18             	sub    $0x18,%esp
f010123b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo *pg = page_lookup(pgdir, va, &p);
f010123e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101241:	50                   	push   %eax
f0101242:	53                   	push   %ebx
f0101243:	ff 75 08             	push   0x8(%ebp)
f0101246:	e8 78 ff ff ff       	call   f01011c3 <page_lookup>
	if (pg == NULL) 
f010124b:	83 c4 10             	add    $0x10,%esp
f010124e:	85 c0                	test   %eax,%eax
f0101250:	74 18                	je     f010126a <page_remove+0x36>
	page_decref(pg);
f0101252:	83 ec 0c             	sub    $0xc,%esp
f0101255:	50                   	push   %eax
f0101256:	e8 e1 fd ff ff       	call   f010103c <page_decref>
	*p = 0;
f010125b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010125e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101264:	0f 01 3b             	invlpg (%ebx)
f0101267:	83 c4 10             	add    $0x10,%esp
}
f010126a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010126d:	c9                   	leave  
f010126e:	c3                   	ret    

f010126f <page_insert>:
{
f010126f:	55                   	push   %ebp
f0101270:	89 e5                	mov    %esp,%ebp
f0101272:	57                   	push   %edi
f0101273:	56                   	push   %esi
f0101274:	53                   	push   %ebx
f0101275:	83 ec 10             	sub    $0x10,%esp
f0101278:	e8 f6 1e 00 00       	call   f0103173 <__x86.get_pc_thunk.di>
f010127d:	81 c7 af e6 07 00    	add    $0x7e6af,%edi
f0101283:	8b 75 08             	mov    0x8(%ebp),%esi
	uintptr_t* p = pgdir_walk(pgdir, va, 1);
f0101286:	6a 01                	push   $0x1
f0101288:	ff 75 10             	push   0x10(%ebp)
f010128b:	56                   	push   %esi
f010128c:	e8 d4 fd ff ff       	call   f0101065 <pgdir_walk>
	if (p == NULL) 
f0101291:	83 c4 10             	add    $0x10,%esp
f0101294:	85 c0                	test   %eax,%eax
f0101296:	74 50                	je     f01012e8 <page_insert+0x79>
f0101298:	89 c3                	mov    %eax,%ebx
	pp->pp_ref ++;
f010129a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010129d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	if ((*p & PTE_P) == 1) 
f01012a2:	f6 03 01             	testb  $0x1,(%ebx)
f01012a5:	75 30                	jne    f01012d7 <page_insert+0x68>
	return (pp - pages) << PGSHIFT;
f01012a7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012aa:	2b 87 0c 1a 00 00    	sub    0x1a0c(%edi),%eax
f01012b0:	c1 f8 03             	sar    $0x3,%eax
f01012b3:	c1 e0 0c             	shl    $0xc,%eax
	*p = page2pa(pp) | perm | PTE_P;
f01012b6:	0b 45 14             	or     0x14(%ebp),%eax
f01012b9:	83 c8 01             	or     $0x1,%eax
f01012bc:	89 03                	mov    %eax,(%ebx)
	*(pgdir + PDX(va)) |= perm;
f01012be:	8b 45 10             	mov    0x10(%ebp),%eax
f01012c1:	c1 e8 16             	shr    $0x16,%eax
f01012c4:	8b 55 14             	mov    0x14(%ebp),%edx
f01012c7:	09 14 86             	or     %edx,(%esi,%eax,4)
	return 0;
f01012ca:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01012cf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012d2:	5b                   	pop    %ebx
f01012d3:	5e                   	pop    %esi
f01012d4:	5f                   	pop    %edi
f01012d5:	5d                   	pop    %ebp
f01012d6:	c3                   	ret    
		page_remove(pgdir, va);
f01012d7:	83 ec 08             	sub    $0x8,%esp
f01012da:	ff 75 10             	push   0x10(%ebp)
f01012dd:	56                   	push   %esi
f01012de:	e8 51 ff ff ff       	call   f0101234 <page_remove>
f01012e3:	83 c4 10             	add    $0x10,%esp
f01012e6:	eb bf                	jmp    f01012a7 <page_insert+0x38>
		return -E_NO_MEM;
f01012e8:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01012ed:	eb e0                	jmp    f01012cf <page_insert+0x60>

f01012ef <mem_init>:
{
f01012ef:	55                   	push   %ebp
f01012f0:	89 e5                	mov    %esp,%ebp
f01012f2:	57                   	push   %edi
f01012f3:	56                   	push   %esi
f01012f4:	53                   	push   %ebx
f01012f5:	83 ec 3c             	sub    $0x3c,%esp
f01012f8:	e8 fc f3 ff ff       	call   f01006f9 <__x86.get_pc_thunk.ax>
f01012fd:	05 2f e6 07 00       	add    $0x7e62f,%eax
f0101302:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	basemem = nvram_read(NVRAM_BASELO);
f0101305:	b8 15 00 00 00       	mov    $0x15,%eax
f010130a:	e8 1b f7 ff ff       	call   f0100a2a <nvram_read>
f010130f:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101311:	b8 17 00 00 00       	mov    $0x17,%eax
f0101316:	e8 0f f7 ff ff       	call   f0100a2a <nvram_read>
f010131b:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010131d:	b8 34 00 00 00       	mov    $0x34,%eax
f0101322:	e8 03 f7 ff ff       	call   f0100a2a <nvram_read>
	if (ext16mem)
f0101327:	c1 e0 06             	shl    $0x6,%eax
f010132a:	0f 84 ba 00 00 00    	je     f01013ea <mem_init+0xfb>
		totalmem = 16 * 1024 + ext16mem;
f0101330:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f0101335:	89 c2                	mov    %eax,%edx
f0101337:	c1 ea 02             	shr    $0x2,%edx
f010133a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010133d:	89 91 14 1a 00 00    	mov    %edx,0x1a14(%ecx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101343:	89 c2                	mov    %eax,%edx
f0101345:	29 da                	sub    %ebx,%edx
f0101347:	52                   	push   %edx
f0101348:	53                   	push   %ebx
f0101349:	50                   	push   %eax
f010134a:	8d 81 68 63 f8 ff    	lea    -0x79c98(%ecx),%eax
f0101350:	50                   	push   %eax
f0101351:	89 cb                	mov    %ecx,%ebx
f0101353:	e8 bd 25 00 00       	call   f0103915 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101358:	b8 00 10 00 00       	mov    $0x1000,%eax
f010135d:	e8 fe f6 ff ff       	call   f0100a60 <boot_alloc>
f0101362:	89 83 10 1a 00 00    	mov    %eax,0x1a10(%ebx)
	memset(kern_pgdir, 0, PGSIZE);
f0101368:	83 c4 0c             	add    $0xc,%esp
f010136b:	68 00 10 00 00       	push   $0x1000
f0101370:	6a 00                	push   $0x0
f0101372:	50                   	push   %eax
f0101373:	e8 e4 3b 00 00       	call   f0104f5c <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101378:	8b 83 10 1a 00 00    	mov    0x1a10(%ebx),%eax
	if ((uint32_t)kva < KERNBASE)
f010137e:	83 c4 10             	add    $0x10,%esp
f0101381:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101386:	76 72                	jbe    f01013fa <mem_init+0x10b>
	return (physaddr_t)kva - KERNBASE;
f0101388:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010138e:	83 ca 05             	or     $0x5,%edx
f0101391:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo*)boot_alloc(sizeof(struct PageInfo) * npages);
f0101397:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010139a:	8b 87 14 1a 00 00    	mov    0x1a14(%edi),%eax
f01013a0:	c1 e0 03             	shl    $0x3,%eax
f01013a3:	e8 b8 f6 ff ff       	call   f0100a60 <boot_alloc>
f01013a8:	89 87 0c 1a 00 00    	mov    %eax,0x1a0c(%edi)
	envs = (struct Env*)boot_alloc(sizeof(struct Env) * NENV);
f01013ae:	b8 00 80 01 00       	mov    $0x18000,%eax
f01013b3:	e8 a8 f6 ff ff       	call   f0100a60 <boot_alloc>
f01013b8:	89 c2                	mov    %eax,%edx
f01013ba:	c7 c0 54 13 18 f0    	mov    $0xf0181354,%eax
f01013c0:	89 10                	mov    %edx,(%eax)
	page_init();
f01013c2:	e8 0f fb ff ff       	call   f0100ed6 <page_init>
	check_page_free_list(1);
f01013c7:	b8 01 00 00 00       	mov    $0x1,%eax
f01013cc:	e8 99 f7 ff ff       	call   f0100b6a <check_page_free_list>
	if (!pages)
f01013d1:	83 bf 0c 1a 00 00 00 	cmpl   $0x0,0x1a0c(%edi)
f01013d8:	74 3c                	je     f0101416 <mem_init+0x127>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013da:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013dd:	8b 80 20 1a 00 00    	mov    0x1a20(%eax),%eax
f01013e3:	be 00 00 00 00       	mov    $0x0,%esi
f01013e8:	eb 4f                	jmp    f0101439 <mem_init+0x14a>
		totalmem = 1 * 1024 + extmem;
f01013ea:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01013f0:	85 f6                	test   %esi,%esi
f01013f2:	0f 44 c3             	cmove  %ebx,%eax
f01013f5:	e9 3b ff ff ff       	jmp    f0101335 <mem_init+0x46>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01013fa:	50                   	push   %eax
f01013fb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01013fe:	8d 83 a4 63 f8 ff    	lea    -0x79c5c(%ebx),%eax
f0101404:	50                   	push   %eax
f0101405:	68 95 00 00 00       	push   $0x95
f010140a:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0101410:	50                   	push   %eax
f0101411:	e8 9b ec ff ff       	call   f01000b1 <_panic>
		panic("'pages' is a null pointer!");
f0101416:	83 ec 04             	sub    $0x4,%esp
f0101419:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010141c:	8d 83 0f 60 f8 ff    	lea    -0x79ff1(%ebx),%eax
f0101422:	50                   	push   %eax
f0101423:	68 b1 02 00 00       	push   $0x2b1
f0101428:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f010142e:	50                   	push   %eax
f010142f:	e8 7d ec ff ff       	call   f01000b1 <_panic>
		++nfree;
f0101434:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101437:	8b 00                	mov    (%eax),%eax
f0101439:	85 c0                	test   %eax,%eax
f010143b:	75 f7                	jne    f0101434 <mem_init+0x145>
	assert((pp0 = page_alloc(0)));
f010143d:	83 ec 0c             	sub    $0xc,%esp
f0101440:	6a 00                	push   $0x0
f0101442:	e8 50 fb ff ff       	call   f0100f97 <page_alloc>
f0101447:	89 c3                	mov    %eax,%ebx
f0101449:	83 c4 10             	add    $0x10,%esp
f010144c:	85 c0                	test   %eax,%eax
f010144e:	0f 84 3a 02 00 00    	je     f010168e <mem_init+0x39f>
	assert((pp1 = page_alloc(0)));
f0101454:	83 ec 0c             	sub    $0xc,%esp
f0101457:	6a 00                	push   $0x0
f0101459:	e8 39 fb ff ff       	call   f0100f97 <page_alloc>
f010145e:	89 c7                	mov    %eax,%edi
f0101460:	83 c4 10             	add    $0x10,%esp
f0101463:	85 c0                	test   %eax,%eax
f0101465:	0f 84 45 02 00 00    	je     f01016b0 <mem_init+0x3c1>
	assert((pp2 = page_alloc(0)));
f010146b:	83 ec 0c             	sub    $0xc,%esp
f010146e:	6a 00                	push   $0x0
f0101470:	e8 22 fb ff ff       	call   f0100f97 <page_alloc>
f0101475:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101478:	83 c4 10             	add    $0x10,%esp
f010147b:	85 c0                	test   %eax,%eax
f010147d:	0f 84 4f 02 00 00    	je     f01016d2 <mem_init+0x3e3>
	assert(pp1 && pp1 != pp0);
f0101483:	39 fb                	cmp    %edi,%ebx
f0101485:	0f 84 69 02 00 00    	je     f01016f4 <mem_init+0x405>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010148b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010148e:	39 c3                	cmp    %eax,%ebx
f0101490:	0f 84 80 02 00 00    	je     f0101716 <mem_init+0x427>
f0101496:	39 c7                	cmp    %eax,%edi
f0101498:	0f 84 78 02 00 00    	je     f0101716 <mem_init+0x427>
	return (pp - pages) << PGSHIFT;
f010149e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014a1:	8b 88 0c 1a 00 00    	mov    0x1a0c(%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014a7:	8b 90 14 1a 00 00    	mov    0x1a14(%eax),%edx
f01014ad:	c1 e2 0c             	shl    $0xc,%edx
f01014b0:	89 d8                	mov    %ebx,%eax
f01014b2:	29 c8                	sub    %ecx,%eax
f01014b4:	c1 f8 03             	sar    $0x3,%eax
f01014b7:	c1 e0 0c             	shl    $0xc,%eax
f01014ba:	39 d0                	cmp    %edx,%eax
f01014bc:	0f 83 76 02 00 00    	jae    f0101738 <mem_init+0x449>
f01014c2:	89 f8                	mov    %edi,%eax
f01014c4:	29 c8                	sub    %ecx,%eax
f01014c6:	c1 f8 03             	sar    $0x3,%eax
f01014c9:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f01014cc:	39 c2                	cmp    %eax,%edx
f01014ce:	0f 86 86 02 00 00    	jbe    f010175a <mem_init+0x46b>
f01014d4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01014d7:	29 c8                	sub    %ecx,%eax
f01014d9:	c1 f8 03             	sar    $0x3,%eax
f01014dc:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f01014df:	39 c2                	cmp    %eax,%edx
f01014e1:	0f 86 95 02 00 00    	jbe    f010177c <mem_init+0x48d>
	fl = page_free_list;
f01014e7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014ea:	8b 88 20 1a 00 00    	mov    0x1a20(%eax),%ecx
f01014f0:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f01014f3:	c7 80 20 1a 00 00 00 	movl   $0x0,0x1a20(%eax)
f01014fa:	00 00 00 
	assert(!page_alloc(0));
f01014fd:	83 ec 0c             	sub    $0xc,%esp
f0101500:	6a 00                	push   $0x0
f0101502:	e8 90 fa ff ff       	call   f0100f97 <page_alloc>
f0101507:	83 c4 10             	add    $0x10,%esp
f010150a:	85 c0                	test   %eax,%eax
f010150c:	0f 85 8c 02 00 00    	jne    f010179e <mem_init+0x4af>
	page_free(pp0);
f0101512:	83 ec 0c             	sub    $0xc,%esp
f0101515:	53                   	push   %ebx
f0101516:	e8 01 fb ff ff       	call   f010101c <page_free>
	page_free(pp1);
f010151b:	89 3c 24             	mov    %edi,(%esp)
f010151e:	e8 f9 fa ff ff       	call   f010101c <page_free>
	page_free(pp2);
f0101523:	83 c4 04             	add    $0x4,%esp
f0101526:	ff 75 d0             	push   -0x30(%ebp)
f0101529:	e8 ee fa ff ff       	call   f010101c <page_free>
	assert((pp0 = page_alloc(0)));
f010152e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101535:	e8 5d fa ff ff       	call   f0100f97 <page_alloc>
f010153a:	89 c7                	mov    %eax,%edi
f010153c:	83 c4 10             	add    $0x10,%esp
f010153f:	85 c0                	test   %eax,%eax
f0101541:	0f 84 79 02 00 00    	je     f01017c0 <mem_init+0x4d1>
	assert((pp1 = page_alloc(0)));
f0101547:	83 ec 0c             	sub    $0xc,%esp
f010154a:	6a 00                	push   $0x0
f010154c:	e8 46 fa ff ff       	call   f0100f97 <page_alloc>
f0101551:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101554:	83 c4 10             	add    $0x10,%esp
f0101557:	85 c0                	test   %eax,%eax
f0101559:	0f 84 83 02 00 00    	je     f01017e2 <mem_init+0x4f3>
	assert((pp2 = page_alloc(0)));
f010155f:	83 ec 0c             	sub    $0xc,%esp
f0101562:	6a 00                	push   $0x0
f0101564:	e8 2e fa ff ff       	call   f0100f97 <page_alloc>
f0101569:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010156c:	83 c4 10             	add    $0x10,%esp
f010156f:	85 c0                	test   %eax,%eax
f0101571:	0f 84 8d 02 00 00    	je     f0101804 <mem_init+0x515>
	assert(pp1 && pp1 != pp0);
f0101577:	3b 7d d0             	cmp    -0x30(%ebp),%edi
f010157a:	0f 84 a6 02 00 00    	je     f0101826 <mem_init+0x537>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101580:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101583:	39 c7                	cmp    %eax,%edi
f0101585:	0f 84 bd 02 00 00    	je     f0101848 <mem_init+0x559>
f010158b:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010158e:	0f 84 b4 02 00 00    	je     f0101848 <mem_init+0x559>
	assert(!page_alloc(0));
f0101594:	83 ec 0c             	sub    $0xc,%esp
f0101597:	6a 00                	push   $0x0
f0101599:	e8 f9 f9 ff ff       	call   f0100f97 <page_alloc>
f010159e:	83 c4 10             	add    $0x10,%esp
f01015a1:	85 c0                	test   %eax,%eax
f01015a3:	0f 85 c1 02 00 00    	jne    f010186a <mem_init+0x57b>
f01015a9:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01015ac:	89 f8                	mov    %edi,%eax
f01015ae:	2b 81 0c 1a 00 00    	sub    0x1a0c(%ecx),%eax
f01015b4:	c1 f8 03             	sar    $0x3,%eax
f01015b7:	89 c2                	mov    %eax,%edx
f01015b9:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01015bc:	25 ff ff 0f 00       	and    $0xfffff,%eax
f01015c1:	3b 81 14 1a 00 00    	cmp    0x1a14(%ecx),%eax
f01015c7:	0f 83 bf 02 00 00    	jae    f010188c <mem_init+0x59d>
	memset(page2kva(pp0), 1, PGSIZE);
f01015cd:	83 ec 04             	sub    $0x4,%esp
f01015d0:	68 00 10 00 00       	push   $0x1000
f01015d5:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01015d7:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f01015dd:	52                   	push   %edx
f01015de:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01015e1:	e8 76 39 00 00       	call   f0104f5c <memset>
	page_free(pp0);
f01015e6:	89 3c 24             	mov    %edi,(%esp)
f01015e9:	e8 2e fa ff ff       	call   f010101c <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01015ee:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01015f5:	e8 9d f9 ff ff       	call   f0100f97 <page_alloc>
f01015fa:	83 c4 10             	add    $0x10,%esp
f01015fd:	85 c0                	test   %eax,%eax
f01015ff:	0f 84 9f 02 00 00    	je     f01018a4 <mem_init+0x5b5>
	assert(pp && pp0 == pp);
f0101605:	39 c7                	cmp    %eax,%edi
f0101607:	0f 85 b9 02 00 00    	jne    f01018c6 <mem_init+0x5d7>
	return (pp - pages) << PGSHIFT;
f010160d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101610:	2b 81 0c 1a 00 00    	sub    0x1a0c(%ecx),%eax
f0101616:	c1 f8 03             	sar    $0x3,%eax
f0101619:	89 c2                	mov    %eax,%edx
f010161b:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010161e:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101623:	3b 81 14 1a 00 00    	cmp    0x1a14(%ecx),%eax
f0101629:	0f 83 b9 02 00 00    	jae    f01018e8 <mem_init+0x5f9>
	return (void *)(pa + KERNBASE);
f010162f:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f0101635:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f010163b:	80 38 00             	cmpb   $0x0,(%eax)
f010163e:	0f 85 bc 02 00 00    	jne    f0101900 <mem_init+0x611>
	for (i = 0; i < PGSIZE; i++)
f0101644:	83 c0 01             	add    $0x1,%eax
f0101647:	39 d0                	cmp    %edx,%eax
f0101649:	75 f0                	jne    f010163b <mem_init+0x34c>
	page_free_list = fl;
f010164b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010164e:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101651:	89 8b 20 1a 00 00    	mov    %ecx,0x1a20(%ebx)
	page_free(pp0);
f0101657:	83 ec 0c             	sub    $0xc,%esp
f010165a:	57                   	push   %edi
f010165b:	e8 bc f9 ff ff       	call   f010101c <page_free>
	page_free(pp1);
f0101660:	83 c4 04             	add    $0x4,%esp
f0101663:	ff 75 d0             	push   -0x30(%ebp)
f0101666:	e8 b1 f9 ff ff       	call   f010101c <page_free>
	page_free(pp2);
f010166b:	83 c4 04             	add    $0x4,%esp
f010166e:	ff 75 cc             	push   -0x34(%ebp)
f0101671:	e8 a6 f9 ff ff       	call   f010101c <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101676:	8b 83 20 1a 00 00    	mov    0x1a20(%ebx),%eax
f010167c:	83 c4 10             	add    $0x10,%esp
f010167f:	85 c0                	test   %eax,%eax
f0101681:	0f 84 9b 02 00 00    	je     f0101922 <mem_init+0x633>
		--nfree;
f0101687:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010168a:	8b 00                	mov    (%eax),%eax
f010168c:	eb f1                	jmp    f010167f <mem_init+0x390>
	assert((pp0 = page_alloc(0)));
f010168e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101691:	8d 83 2a 60 f8 ff    	lea    -0x79fd6(%ebx),%eax
f0101697:	50                   	push   %eax
f0101698:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010169e:	50                   	push   %eax
f010169f:	68 b9 02 00 00       	push   $0x2b9
f01016a4:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01016aa:	50                   	push   %eax
f01016ab:	e8 01 ea ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f01016b0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016b3:	8d 83 40 60 f8 ff    	lea    -0x79fc0(%ebx),%eax
f01016b9:	50                   	push   %eax
f01016ba:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01016c0:	50                   	push   %eax
f01016c1:	68 ba 02 00 00       	push   $0x2ba
f01016c6:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01016cc:	50                   	push   %eax
f01016cd:	e8 df e9 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f01016d2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016d5:	8d 83 56 60 f8 ff    	lea    -0x79faa(%ebx),%eax
f01016db:	50                   	push   %eax
f01016dc:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01016e2:	50                   	push   %eax
f01016e3:	68 bb 02 00 00       	push   $0x2bb
f01016e8:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01016ee:	50                   	push   %eax
f01016ef:	e8 bd e9 ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f01016f4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016f7:	8d 83 6c 60 f8 ff    	lea    -0x79f94(%ebx),%eax
f01016fd:	50                   	push   %eax
f01016fe:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0101704:	50                   	push   %eax
f0101705:	68 be 02 00 00       	push   $0x2be
f010170a:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0101710:	50                   	push   %eax
f0101711:	e8 9b e9 ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101716:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101719:	8d 83 c8 63 f8 ff    	lea    -0x79c38(%ebx),%eax
f010171f:	50                   	push   %eax
f0101720:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0101726:	50                   	push   %eax
f0101727:	68 bf 02 00 00       	push   $0x2bf
f010172c:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0101732:	50                   	push   %eax
f0101733:	e8 79 e9 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101738:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010173b:	8d 83 7e 60 f8 ff    	lea    -0x79f82(%ebx),%eax
f0101741:	50                   	push   %eax
f0101742:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0101748:	50                   	push   %eax
f0101749:	68 c0 02 00 00       	push   $0x2c0
f010174e:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0101754:	50                   	push   %eax
f0101755:	e8 57 e9 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010175a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010175d:	8d 83 9b 60 f8 ff    	lea    -0x79f65(%ebx),%eax
f0101763:	50                   	push   %eax
f0101764:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010176a:	50                   	push   %eax
f010176b:	68 c1 02 00 00       	push   $0x2c1
f0101770:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0101776:	50                   	push   %eax
f0101777:	e8 35 e9 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010177c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010177f:	8d 83 b8 60 f8 ff    	lea    -0x79f48(%ebx),%eax
f0101785:	50                   	push   %eax
f0101786:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010178c:	50                   	push   %eax
f010178d:	68 c2 02 00 00       	push   $0x2c2
f0101792:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0101798:	50                   	push   %eax
f0101799:	e8 13 e9 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f010179e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017a1:	8d 83 d5 60 f8 ff    	lea    -0x79f2b(%ebx),%eax
f01017a7:	50                   	push   %eax
f01017a8:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01017ae:	50                   	push   %eax
f01017af:	68 c9 02 00 00       	push   $0x2c9
f01017b4:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01017ba:	50                   	push   %eax
f01017bb:	e8 f1 e8 ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f01017c0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017c3:	8d 83 2a 60 f8 ff    	lea    -0x79fd6(%ebx),%eax
f01017c9:	50                   	push   %eax
f01017ca:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01017d0:	50                   	push   %eax
f01017d1:	68 d0 02 00 00       	push   $0x2d0
f01017d6:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01017dc:	50                   	push   %eax
f01017dd:	e8 cf e8 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f01017e2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017e5:	8d 83 40 60 f8 ff    	lea    -0x79fc0(%ebx),%eax
f01017eb:	50                   	push   %eax
f01017ec:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01017f2:	50                   	push   %eax
f01017f3:	68 d1 02 00 00       	push   $0x2d1
f01017f8:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01017fe:	50                   	push   %eax
f01017ff:	e8 ad e8 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f0101804:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101807:	8d 83 56 60 f8 ff    	lea    -0x79faa(%ebx),%eax
f010180d:	50                   	push   %eax
f010180e:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0101814:	50                   	push   %eax
f0101815:	68 d2 02 00 00       	push   $0x2d2
f010181a:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0101820:	50                   	push   %eax
f0101821:	e8 8b e8 ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f0101826:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101829:	8d 83 6c 60 f8 ff    	lea    -0x79f94(%ebx),%eax
f010182f:	50                   	push   %eax
f0101830:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0101836:	50                   	push   %eax
f0101837:	68 d4 02 00 00       	push   $0x2d4
f010183c:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0101842:	50                   	push   %eax
f0101843:	e8 69 e8 ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101848:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010184b:	8d 83 c8 63 f8 ff    	lea    -0x79c38(%ebx),%eax
f0101851:	50                   	push   %eax
f0101852:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0101858:	50                   	push   %eax
f0101859:	68 d5 02 00 00       	push   $0x2d5
f010185e:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0101864:	50                   	push   %eax
f0101865:	e8 47 e8 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f010186a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010186d:	8d 83 d5 60 f8 ff    	lea    -0x79f2b(%ebx),%eax
f0101873:	50                   	push   %eax
f0101874:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010187a:	50                   	push   %eax
f010187b:	68 d6 02 00 00       	push   $0x2d6
f0101880:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0101886:	50                   	push   %eax
f0101887:	e8 25 e8 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010188c:	52                   	push   %edx
f010188d:	89 cb                	mov    %ecx,%ebx
f010188f:	8d 81 3c 62 f8 ff    	lea    -0x79dc4(%ecx),%eax
f0101895:	50                   	push   %eax
f0101896:	6a 56                	push   $0x56
f0101898:	8d 81 55 5f f8 ff    	lea    -0x7a0ab(%ecx),%eax
f010189e:	50                   	push   %eax
f010189f:	e8 0d e8 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01018a4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018a7:	8d 83 e4 60 f8 ff    	lea    -0x79f1c(%ebx),%eax
f01018ad:	50                   	push   %eax
f01018ae:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01018b4:	50                   	push   %eax
f01018b5:	68 db 02 00 00       	push   $0x2db
f01018ba:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01018c0:	50                   	push   %eax
f01018c1:	e8 eb e7 ff ff       	call   f01000b1 <_panic>
	assert(pp && pp0 == pp);
f01018c6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018c9:	8d 83 02 61 f8 ff    	lea    -0x79efe(%ebx),%eax
f01018cf:	50                   	push   %eax
f01018d0:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01018d6:	50                   	push   %eax
f01018d7:	68 dc 02 00 00       	push   $0x2dc
f01018dc:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01018e2:	50                   	push   %eax
f01018e3:	e8 c9 e7 ff ff       	call   f01000b1 <_panic>
f01018e8:	52                   	push   %edx
f01018e9:	89 cb                	mov    %ecx,%ebx
f01018eb:	8d 81 3c 62 f8 ff    	lea    -0x79dc4(%ecx),%eax
f01018f1:	50                   	push   %eax
f01018f2:	6a 56                	push   $0x56
f01018f4:	8d 81 55 5f f8 ff    	lea    -0x7a0ab(%ecx),%eax
f01018fa:	50                   	push   %eax
f01018fb:	e8 b1 e7 ff ff       	call   f01000b1 <_panic>
		assert(c[i] == 0);
f0101900:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101903:	8d 83 12 61 f8 ff    	lea    -0x79eee(%ebx),%eax
f0101909:	50                   	push   %eax
f010190a:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0101910:	50                   	push   %eax
f0101911:	68 df 02 00 00       	push   $0x2df
f0101916:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f010191c:	50                   	push   %eax
f010191d:	e8 8f e7 ff ff       	call   f01000b1 <_panic>
	assert(nfree == 0);
f0101922:	85 f6                	test   %esi,%esi
f0101924:	0f 85 31 08 00 00    	jne    f010215b <mem_init+0xe6c>
	cprintf("check_page_alloc() succeeded!\n");
f010192a:	83 ec 0c             	sub    $0xc,%esp
f010192d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101930:	8d 83 e8 63 f8 ff    	lea    -0x79c18(%ebx),%eax
f0101936:	50                   	push   %eax
f0101937:	e8 d9 1f 00 00       	call   f0103915 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010193c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101943:	e8 4f f6 ff ff       	call   f0100f97 <page_alloc>
f0101948:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010194b:	83 c4 10             	add    $0x10,%esp
f010194e:	85 c0                	test   %eax,%eax
f0101950:	0f 84 27 08 00 00    	je     f010217d <mem_init+0xe8e>
	assert((pp1 = page_alloc(0)));
f0101956:	83 ec 0c             	sub    $0xc,%esp
f0101959:	6a 00                	push   $0x0
f010195b:	e8 37 f6 ff ff       	call   f0100f97 <page_alloc>
f0101960:	89 c7                	mov    %eax,%edi
f0101962:	83 c4 10             	add    $0x10,%esp
f0101965:	85 c0                	test   %eax,%eax
f0101967:	0f 84 32 08 00 00    	je     f010219f <mem_init+0xeb0>
	assert((pp2 = page_alloc(0)));
f010196d:	83 ec 0c             	sub    $0xc,%esp
f0101970:	6a 00                	push   $0x0
f0101972:	e8 20 f6 ff ff       	call   f0100f97 <page_alloc>
f0101977:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010197a:	83 c4 10             	add    $0x10,%esp
f010197d:	85 c0                	test   %eax,%eax
f010197f:	0f 84 3c 08 00 00    	je     f01021c1 <mem_init+0xed2>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101985:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0101988:	0f 84 55 08 00 00    	je     f01021e3 <mem_init+0xef4>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010198e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101991:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101994:	0f 84 6b 08 00 00    	je     f0102205 <mem_init+0xf16>
f010199a:	39 c7                	cmp    %eax,%edi
f010199c:	0f 84 63 08 00 00    	je     f0102205 <mem_init+0xf16>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01019a2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019a5:	8b 88 20 1a 00 00    	mov    0x1a20(%eax),%ecx
f01019ab:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f01019ae:	c7 80 20 1a 00 00 00 	movl   $0x0,0x1a20(%eax)
f01019b5:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01019b8:	83 ec 0c             	sub    $0xc,%esp
f01019bb:	6a 00                	push   $0x0
f01019bd:	e8 d5 f5 ff ff       	call   f0100f97 <page_alloc>
f01019c2:	83 c4 10             	add    $0x10,%esp
f01019c5:	85 c0                	test   %eax,%eax
f01019c7:	0f 85 5a 08 00 00    	jne    f0102227 <mem_init+0xf38>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01019cd:	83 ec 04             	sub    $0x4,%esp
f01019d0:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019d3:	50                   	push   %eax
f01019d4:	6a 00                	push   $0x0
f01019d6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019d9:	ff b0 10 1a 00 00    	push   0x1a10(%eax)
f01019df:	e8 df f7 ff ff       	call   f01011c3 <page_lookup>
f01019e4:	83 c4 10             	add    $0x10,%esp
f01019e7:	85 c0                	test   %eax,%eax
f01019e9:	0f 85 5a 08 00 00    	jne    f0102249 <mem_init+0xf5a>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019ef:	6a 02                	push   $0x2
f01019f1:	6a 00                	push   $0x0
f01019f3:	57                   	push   %edi
f01019f4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019f7:	ff b0 10 1a 00 00    	push   0x1a10(%eax)
f01019fd:	e8 6d f8 ff ff       	call   f010126f <page_insert>
f0101a02:	83 c4 10             	add    $0x10,%esp
f0101a05:	85 c0                	test   %eax,%eax
f0101a07:	0f 89 5e 08 00 00    	jns    f010226b <mem_init+0xf7c>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a0d:	83 ec 0c             	sub    $0xc,%esp
f0101a10:	ff 75 cc             	push   -0x34(%ebp)
f0101a13:	e8 04 f6 ff ff       	call   f010101c <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a18:	6a 02                	push   $0x2
f0101a1a:	6a 00                	push   $0x0
f0101a1c:	57                   	push   %edi
f0101a1d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a20:	ff b0 10 1a 00 00    	push   0x1a10(%eax)
f0101a26:	e8 44 f8 ff ff       	call   f010126f <page_insert>
f0101a2b:	83 c4 20             	add    $0x20,%esp
f0101a2e:	85 c0                	test   %eax,%eax
f0101a30:	0f 85 57 08 00 00    	jne    f010228d <mem_init+0xf9e>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a36:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a39:	8b 98 10 1a 00 00    	mov    0x1a10(%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101a3f:	8b b0 0c 1a 00 00    	mov    0x1a0c(%eax),%esi
f0101a45:	8b 13                	mov    (%ebx),%edx
f0101a47:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a4d:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101a50:	29 f0                	sub    %esi,%eax
f0101a52:	c1 f8 03             	sar    $0x3,%eax
f0101a55:	c1 e0 0c             	shl    $0xc,%eax
f0101a58:	39 c2                	cmp    %eax,%edx
f0101a5a:	0f 85 4f 08 00 00    	jne    f01022af <mem_init+0xfc0>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a60:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a65:	89 d8                	mov    %ebx,%eax
f0101a67:	e8 82 f0 ff ff       	call   f0100aee <check_va2pa>
f0101a6c:	89 c2                	mov    %eax,%edx
f0101a6e:	89 f8                	mov    %edi,%eax
f0101a70:	29 f0                	sub    %esi,%eax
f0101a72:	c1 f8 03             	sar    $0x3,%eax
f0101a75:	c1 e0 0c             	shl    $0xc,%eax
f0101a78:	39 c2                	cmp    %eax,%edx
f0101a7a:	0f 85 51 08 00 00    	jne    f01022d1 <mem_init+0xfe2>
	assert(pp1->pp_ref == 1);
f0101a80:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101a85:	0f 85 68 08 00 00    	jne    f01022f3 <mem_init+0x1004>
	assert(pp0->pp_ref == 1);
f0101a8b:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101a8e:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a93:	0f 85 7c 08 00 00    	jne    f0102315 <mem_init+0x1026>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a99:	6a 02                	push   $0x2
f0101a9b:	68 00 10 00 00       	push   $0x1000
f0101aa0:	ff 75 d0             	push   -0x30(%ebp)
f0101aa3:	53                   	push   %ebx
f0101aa4:	e8 c6 f7 ff ff       	call   f010126f <page_insert>
f0101aa9:	83 c4 10             	add    $0x10,%esp
f0101aac:	85 c0                	test   %eax,%eax
f0101aae:	0f 85 83 08 00 00    	jne    f0102337 <mem_init+0x1048>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ab4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ab9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101abc:	8b 83 10 1a 00 00    	mov    0x1a10(%ebx),%eax
f0101ac2:	e8 27 f0 ff ff       	call   f0100aee <check_va2pa>
f0101ac7:	89 c2                	mov    %eax,%edx
f0101ac9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101acc:	2b 83 0c 1a 00 00    	sub    0x1a0c(%ebx),%eax
f0101ad2:	c1 f8 03             	sar    $0x3,%eax
f0101ad5:	c1 e0 0c             	shl    $0xc,%eax
f0101ad8:	39 c2                	cmp    %eax,%edx
f0101ada:	0f 85 79 08 00 00    	jne    f0102359 <mem_init+0x106a>
	assert(pp2->pp_ref == 1);
f0101ae0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101ae3:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ae8:	0f 85 8d 08 00 00    	jne    f010237b <mem_init+0x108c>

	// should be no free memory
	assert(!page_alloc(0));
f0101aee:	83 ec 0c             	sub    $0xc,%esp
f0101af1:	6a 00                	push   $0x0
f0101af3:	e8 9f f4 ff ff       	call   f0100f97 <page_alloc>
f0101af8:	83 c4 10             	add    $0x10,%esp
f0101afb:	85 c0                	test   %eax,%eax
f0101afd:	0f 85 9a 08 00 00    	jne    f010239d <mem_init+0x10ae>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b03:	6a 02                	push   $0x2
f0101b05:	68 00 10 00 00       	push   $0x1000
f0101b0a:	ff 75 d0             	push   -0x30(%ebp)
f0101b0d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b10:	ff b0 10 1a 00 00    	push   0x1a10(%eax)
f0101b16:	e8 54 f7 ff ff       	call   f010126f <page_insert>
f0101b1b:	83 c4 10             	add    $0x10,%esp
f0101b1e:	85 c0                	test   %eax,%eax
f0101b20:	0f 85 99 08 00 00    	jne    f01023bf <mem_init+0x10d0>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b26:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b2b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101b2e:	8b 83 10 1a 00 00    	mov    0x1a10(%ebx),%eax
f0101b34:	e8 b5 ef ff ff       	call   f0100aee <check_va2pa>
f0101b39:	89 c2                	mov    %eax,%edx
f0101b3b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b3e:	2b 83 0c 1a 00 00    	sub    0x1a0c(%ebx),%eax
f0101b44:	c1 f8 03             	sar    $0x3,%eax
f0101b47:	c1 e0 0c             	shl    $0xc,%eax
f0101b4a:	39 c2                	cmp    %eax,%edx
f0101b4c:	0f 85 8f 08 00 00    	jne    f01023e1 <mem_init+0x10f2>
	assert(pp2->pp_ref == 1);
f0101b52:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b55:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b5a:	0f 85 a3 08 00 00    	jne    f0102403 <mem_init+0x1114>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101b60:	83 ec 0c             	sub    $0xc,%esp
f0101b63:	6a 00                	push   $0x0
f0101b65:	e8 2d f4 ff ff       	call   f0100f97 <page_alloc>
f0101b6a:	83 c4 10             	add    $0x10,%esp
f0101b6d:	85 c0                	test   %eax,%eax
f0101b6f:	0f 85 b0 08 00 00    	jne    f0102425 <mem_init+0x1136>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101b75:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101b78:	8b 91 10 1a 00 00    	mov    0x1a10(%ecx),%edx
f0101b7e:	8b 02                	mov    (%edx),%eax
f0101b80:	89 c3                	mov    %eax,%ebx
f0101b82:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	if (PGNUM(pa) >= npages)
f0101b88:	c1 e8 0c             	shr    $0xc,%eax
f0101b8b:	3b 81 14 1a 00 00    	cmp    0x1a14(%ecx),%eax
f0101b91:	0f 83 b0 08 00 00    	jae    f0102447 <mem_init+0x1158>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101b97:	83 ec 04             	sub    $0x4,%esp
f0101b9a:	6a 00                	push   $0x0
f0101b9c:	68 00 10 00 00       	push   $0x1000
f0101ba1:	52                   	push   %edx
f0101ba2:	e8 be f4 ff ff       	call   f0101065 <pgdir_walk>
f0101ba7:	81 eb fc ff ff 0f    	sub    $0xffffffc,%ebx
f0101bad:	83 c4 10             	add    $0x10,%esp
f0101bb0:	39 d8                	cmp    %ebx,%eax
f0101bb2:	0f 85 aa 08 00 00    	jne    f0102462 <mem_init+0x1173>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101bb8:	6a 06                	push   $0x6
f0101bba:	68 00 10 00 00       	push   $0x1000
f0101bbf:	ff 75 d0             	push   -0x30(%ebp)
f0101bc2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101bc5:	ff b0 10 1a 00 00    	push   0x1a10(%eax)
f0101bcb:	e8 9f f6 ff ff       	call   f010126f <page_insert>
f0101bd0:	83 c4 10             	add    $0x10,%esp
f0101bd3:	85 c0                	test   %eax,%eax
f0101bd5:	0f 85 a9 08 00 00    	jne    f0102484 <mem_init+0x1195>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bdb:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101bde:	8b 9e 10 1a 00 00    	mov    0x1a10(%esi),%ebx
f0101be4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101be9:	89 d8                	mov    %ebx,%eax
f0101beb:	e8 fe ee ff ff       	call   f0100aee <check_va2pa>
f0101bf0:	89 c2                	mov    %eax,%edx
	return (pp - pages) << PGSHIFT;
f0101bf2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101bf5:	2b 86 0c 1a 00 00    	sub    0x1a0c(%esi),%eax
f0101bfb:	c1 f8 03             	sar    $0x3,%eax
f0101bfe:	c1 e0 0c             	shl    $0xc,%eax
f0101c01:	39 c2                	cmp    %eax,%edx
f0101c03:	0f 85 9d 08 00 00    	jne    f01024a6 <mem_init+0x11b7>
	assert(pp2->pp_ref == 1);
f0101c09:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101c0c:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c11:	0f 85 b1 08 00 00    	jne    f01024c8 <mem_init+0x11d9>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101c17:	83 ec 04             	sub    $0x4,%esp
f0101c1a:	6a 00                	push   $0x0
f0101c1c:	68 00 10 00 00       	push   $0x1000
f0101c21:	53                   	push   %ebx
f0101c22:	e8 3e f4 ff ff       	call   f0101065 <pgdir_walk>
f0101c27:	83 c4 10             	add    $0x10,%esp
f0101c2a:	f6 00 04             	testb  $0x4,(%eax)
f0101c2d:	0f 84 b7 08 00 00    	je     f01024ea <mem_init+0x11fb>
	assert(kern_pgdir[0] & PTE_U);
f0101c33:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c36:	8b 80 10 1a 00 00    	mov    0x1a10(%eax),%eax
f0101c3c:	f6 00 04             	testb  $0x4,(%eax)
f0101c3f:	0f 84 c7 08 00 00    	je     f010250c <mem_init+0x121d>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c45:	6a 02                	push   $0x2
f0101c47:	68 00 10 00 00       	push   $0x1000
f0101c4c:	ff 75 d0             	push   -0x30(%ebp)
f0101c4f:	50                   	push   %eax
f0101c50:	e8 1a f6 ff ff       	call   f010126f <page_insert>
f0101c55:	83 c4 10             	add    $0x10,%esp
f0101c58:	85 c0                	test   %eax,%eax
f0101c5a:	0f 85 ce 08 00 00    	jne    f010252e <mem_init+0x123f>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101c60:	83 ec 04             	sub    $0x4,%esp
f0101c63:	6a 00                	push   $0x0
f0101c65:	68 00 10 00 00       	push   $0x1000
f0101c6a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c6d:	ff b0 10 1a 00 00    	push   0x1a10(%eax)
f0101c73:	e8 ed f3 ff ff       	call   f0101065 <pgdir_walk>
f0101c78:	83 c4 10             	add    $0x10,%esp
f0101c7b:	f6 00 02             	testb  $0x2,(%eax)
f0101c7e:	0f 84 cc 08 00 00    	je     f0102550 <mem_init+0x1261>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c84:	83 ec 04             	sub    $0x4,%esp
f0101c87:	6a 00                	push   $0x0
f0101c89:	68 00 10 00 00       	push   $0x1000
f0101c8e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c91:	ff b0 10 1a 00 00    	push   0x1a10(%eax)
f0101c97:	e8 c9 f3 ff ff       	call   f0101065 <pgdir_walk>
f0101c9c:	83 c4 10             	add    $0x10,%esp
f0101c9f:	f6 00 04             	testb  $0x4,(%eax)
f0101ca2:	0f 85 ca 08 00 00    	jne    f0102572 <mem_init+0x1283>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101ca8:	6a 02                	push   $0x2
f0101caa:	68 00 00 40 00       	push   $0x400000
f0101caf:	ff 75 cc             	push   -0x34(%ebp)
f0101cb2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cb5:	ff b0 10 1a 00 00    	push   0x1a10(%eax)
f0101cbb:	e8 af f5 ff ff       	call   f010126f <page_insert>
f0101cc0:	83 c4 10             	add    $0x10,%esp
f0101cc3:	85 c0                	test   %eax,%eax
f0101cc5:	0f 89 c9 08 00 00    	jns    f0102594 <mem_init+0x12a5>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101ccb:	6a 02                	push   $0x2
f0101ccd:	68 00 10 00 00       	push   $0x1000
f0101cd2:	57                   	push   %edi
f0101cd3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cd6:	ff b0 10 1a 00 00    	push   0x1a10(%eax)
f0101cdc:	e8 8e f5 ff ff       	call   f010126f <page_insert>
f0101ce1:	83 c4 10             	add    $0x10,%esp
f0101ce4:	85 c0                	test   %eax,%eax
f0101ce6:	0f 85 ca 08 00 00    	jne    f01025b6 <mem_init+0x12c7>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101cec:	83 ec 04             	sub    $0x4,%esp
f0101cef:	6a 00                	push   $0x0
f0101cf1:	68 00 10 00 00       	push   $0x1000
f0101cf6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cf9:	ff b0 10 1a 00 00    	push   0x1a10(%eax)
f0101cff:	e8 61 f3 ff ff       	call   f0101065 <pgdir_walk>
f0101d04:	83 c4 10             	add    $0x10,%esp
f0101d07:	f6 00 04             	testb  $0x4,(%eax)
f0101d0a:	0f 85 c8 08 00 00    	jne    f01025d8 <mem_init+0x12e9>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101d10:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101d13:	8b b3 10 1a 00 00    	mov    0x1a10(%ebx),%esi
f0101d19:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d1e:	89 f0                	mov    %esi,%eax
f0101d20:	e8 c9 ed ff ff       	call   f0100aee <check_va2pa>
f0101d25:	89 d9                	mov    %ebx,%ecx
f0101d27:	89 fb                	mov    %edi,%ebx
f0101d29:	2b 99 0c 1a 00 00    	sub    0x1a0c(%ecx),%ebx
f0101d2f:	c1 fb 03             	sar    $0x3,%ebx
f0101d32:	c1 e3 0c             	shl    $0xc,%ebx
f0101d35:	39 d8                	cmp    %ebx,%eax
f0101d37:	0f 85 bd 08 00 00    	jne    f01025fa <mem_init+0x130b>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d3d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d42:	89 f0                	mov    %esi,%eax
f0101d44:	e8 a5 ed ff ff       	call   f0100aee <check_va2pa>
f0101d49:	39 c3                	cmp    %eax,%ebx
f0101d4b:	0f 85 cb 08 00 00    	jne    f010261c <mem_init+0x132d>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101d51:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101d56:	0f 85 e2 08 00 00    	jne    f010263e <mem_init+0x134f>
	assert(pp2->pp_ref == 0);
f0101d5c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101d5f:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101d64:	0f 85 f6 08 00 00    	jne    f0102660 <mem_init+0x1371>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101d6a:	83 ec 0c             	sub    $0xc,%esp
f0101d6d:	6a 00                	push   $0x0
f0101d6f:	e8 23 f2 ff ff       	call   f0100f97 <page_alloc>
f0101d74:	83 c4 10             	add    $0x10,%esp
f0101d77:	85 c0                	test   %eax,%eax
f0101d79:	0f 84 03 09 00 00    	je     f0102682 <mem_init+0x1393>
f0101d7f:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101d82:	0f 85 fa 08 00 00    	jne    f0102682 <mem_init+0x1393>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d88:	83 ec 08             	sub    $0x8,%esp
f0101d8b:	6a 00                	push   $0x0
f0101d8d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101d90:	ff b3 10 1a 00 00    	push   0x1a10(%ebx)
f0101d96:	e8 99 f4 ff ff       	call   f0101234 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d9b:	8b 9b 10 1a 00 00    	mov    0x1a10(%ebx),%ebx
f0101da1:	ba 00 00 00 00       	mov    $0x0,%edx
f0101da6:	89 d8                	mov    %ebx,%eax
f0101da8:	e8 41 ed ff ff       	call   f0100aee <check_va2pa>
f0101dad:	83 c4 10             	add    $0x10,%esp
f0101db0:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101db3:	0f 85 eb 08 00 00    	jne    f01026a4 <mem_init+0x13b5>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101db9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dbe:	89 d8                	mov    %ebx,%eax
f0101dc0:	e8 29 ed ff ff       	call   f0100aee <check_va2pa>
f0101dc5:	89 c2                	mov    %eax,%edx
f0101dc7:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101dca:	89 f8                	mov    %edi,%eax
f0101dcc:	2b 81 0c 1a 00 00    	sub    0x1a0c(%ecx),%eax
f0101dd2:	c1 f8 03             	sar    $0x3,%eax
f0101dd5:	c1 e0 0c             	shl    $0xc,%eax
f0101dd8:	39 c2                	cmp    %eax,%edx
f0101dda:	0f 85 e6 08 00 00    	jne    f01026c6 <mem_init+0x13d7>
	assert(pp1->pp_ref == 1);
f0101de0:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101de5:	0f 85 fc 08 00 00    	jne    f01026e7 <mem_init+0x13f8>
	assert(pp2->pp_ref == 0);
f0101deb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101dee:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101df3:	0f 85 10 09 00 00    	jne    f0102709 <mem_init+0x141a>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101df9:	6a 00                	push   $0x0
f0101dfb:	68 00 10 00 00       	push   $0x1000
f0101e00:	57                   	push   %edi
f0101e01:	53                   	push   %ebx
f0101e02:	e8 68 f4 ff ff       	call   f010126f <page_insert>
f0101e07:	83 c4 10             	add    $0x10,%esp
f0101e0a:	85 c0                	test   %eax,%eax
f0101e0c:	0f 85 19 09 00 00    	jne    f010272b <mem_init+0x143c>
	assert(pp1->pp_ref);
f0101e12:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101e17:	0f 84 30 09 00 00    	je     f010274d <mem_init+0x145e>
	assert(pp1->pp_link == NULL);
f0101e1d:	83 3f 00             	cmpl   $0x0,(%edi)
f0101e20:	0f 85 49 09 00 00    	jne    f010276f <mem_init+0x1480>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e26:	83 ec 08             	sub    $0x8,%esp
f0101e29:	68 00 10 00 00       	push   $0x1000
f0101e2e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101e31:	ff b3 10 1a 00 00    	push   0x1a10(%ebx)
f0101e37:	e8 f8 f3 ff ff       	call   f0101234 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e3c:	8b 9b 10 1a 00 00    	mov    0x1a10(%ebx),%ebx
f0101e42:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e47:	89 d8                	mov    %ebx,%eax
f0101e49:	e8 a0 ec ff ff       	call   f0100aee <check_va2pa>
f0101e4e:	83 c4 10             	add    $0x10,%esp
f0101e51:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e54:	0f 85 37 09 00 00    	jne    f0102791 <mem_init+0x14a2>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e5a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e5f:	89 d8                	mov    %ebx,%eax
f0101e61:	e8 88 ec ff ff       	call   f0100aee <check_va2pa>
f0101e66:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e69:	0f 85 44 09 00 00    	jne    f01027b3 <mem_init+0x14c4>
	assert(pp1->pp_ref == 0);
f0101e6f:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101e74:	0f 85 5b 09 00 00    	jne    f01027d5 <mem_init+0x14e6>
	assert(pp2->pp_ref == 0);
f0101e7a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101e7d:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e82:	0f 85 6f 09 00 00    	jne    f01027f7 <mem_init+0x1508>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e88:	83 ec 0c             	sub    $0xc,%esp
f0101e8b:	6a 00                	push   $0x0
f0101e8d:	e8 05 f1 ff ff       	call   f0100f97 <page_alloc>
f0101e92:	83 c4 10             	add    $0x10,%esp
f0101e95:	39 c7                	cmp    %eax,%edi
f0101e97:	0f 85 7c 09 00 00    	jne    f0102819 <mem_init+0x152a>
f0101e9d:	85 c0                	test   %eax,%eax
f0101e9f:	0f 84 74 09 00 00    	je     f0102819 <mem_init+0x152a>

	// should be no free memory
	assert(!page_alloc(0));
f0101ea5:	83 ec 0c             	sub    $0xc,%esp
f0101ea8:	6a 00                	push   $0x0
f0101eaa:	e8 e8 f0 ff ff       	call   f0100f97 <page_alloc>
f0101eaf:	83 c4 10             	add    $0x10,%esp
f0101eb2:	85 c0                	test   %eax,%eax
f0101eb4:	0f 85 81 09 00 00    	jne    f010283b <mem_init+0x154c>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101eba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ebd:	8b 88 10 1a 00 00    	mov    0x1a10(%eax),%ecx
f0101ec3:	8b 11                	mov    (%ecx),%edx
f0101ec5:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ecb:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0101ece:	2b 98 0c 1a 00 00    	sub    0x1a0c(%eax),%ebx
f0101ed4:	89 d8                	mov    %ebx,%eax
f0101ed6:	c1 f8 03             	sar    $0x3,%eax
f0101ed9:	c1 e0 0c             	shl    $0xc,%eax
f0101edc:	39 c2                	cmp    %eax,%edx
f0101ede:	0f 85 79 09 00 00    	jne    f010285d <mem_init+0x156e>
	kern_pgdir[0] = 0;
f0101ee4:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101eea:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101eed:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ef2:	0f 85 87 09 00 00    	jne    f010287f <mem_init+0x1590>
	pp0->pp_ref = 0;
f0101ef8:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101efb:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f01:	83 ec 0c             	sub    $0xc,%esp
f0101f04:	50                   	push   %eax
f0101f05:	e8 12 f1 ff ff       	call   f010101c <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f0a:	83 c4 0c             	add    $0xc,%esp
f0101f0d:	6a 01                	push   $0x1
f0101f0f:	68 00 10 40 00       	push   $0x401000
f0101f14:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101f17:	ff b3 10 1a 00 00    	push   0x1a10(%ebx)
f0101f1d:	e8 43 f1 ff ff       	call   f0101065 <pgdir_walk>
f0101f22:	89 c6                	mov    %eax,%esi
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f24:	89 d9                	mov    %ebx,%ecx
f0101f26:	8b 9b 10 1a 00 00    	mov    0x1a10(%ebx),%ebx
f0101f2c:	8b 43 04             	mov    0x4(%ebx),%eax
f0101f2f:	89 c2                	mov    %eax,%edx
f0101f31:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101f37:	8b 89 14 1a 00 00    	mov    0x1a14(%ecx),%ecx
f0101f3d:	c1 e8 0c             	shr    $0xc,%eax
f0101f40:	83 c4 10             	add    $0x10,%esp
f0101f43:	39 c8                	cmp    %ecx,%eax
f0101f45:	0f 83 56 09 00 00    	jae    f01028a1 <mem_init+0x15b2>
	assert(ptep == ptep1 + PTX(va));
f0101f4b:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0101f51:	39 d6                	cmp    %edx,%esi
f0101f53:	0f 85 64 09 00 00    	jne    f01028bd <mem_init+0x15ce>
	kern_pgdir[PDX(va)] = 0;
f0101f59:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f0101f60:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f63:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0101f69:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101f6c:	2b 83 0c 1a 00 00    	sub    0x1a0c(%ebx),%eax
f0101f72:	c1 f8 03             	sar    $0x3,%eax
f0101f75:	89 c2                	mov    %eax,%edx
f0101f77:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101f7a:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101f7f:	39 c1                	cmp    %eax,%ecx
f0101f81:	0f 86 58 09 00 00    	jbe    f01028df <mem_init+0x15f0>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101f87:	83 ec 04             	sub    $0x4,%esp
f0101f8a:	68 00 10 00 00       	push   $0x1000
f0101f8f:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0101f94:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101f9a:	52                   	push   %edx
f0101f9b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101f9e:	e8 b9 2f 00 00       	call   f0104f5c <memset>
	page_free(pp0);
f0101fa3:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101fa6:	89 34 24             	mov    %esi,(%esp)
f0101fa9:	e8 6e f0 ff ff       	call   f010101c <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101fae:	83 c4 0c             	add    $0xc,%esp
f0101fb1:	6a 01                	push   $0x1
f0101fb3:	6a 00                	push   $0x0
f0101fb5:	ff b3 10 1a 00 00    	push   0x1a10(%ebx)
f0101fbb:	e8 a5 f0 ff ff       	call   f0101065 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0101fc0:	89 f0                	mov    %esi,%eax
f0101fc2:	2b 83 0c 1a 00 00    	sub    0x1a0c(%ebx),%eax
f0101fc8:	c1 f8 03             	sar    $0x3,%eax
f0101fcb:	89 c2                	mov    %eax,%edx
f0101fcd:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101fd0:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101fd5:	83 c4 10             	add    $0x10,%esp
f0101fd8:	3b 83 14 1a 00 00    	cmp    0x1a14(%ebx),%eax
f0101fde:	0f 83 11 09 00 00    	jae    f01028f5 <mem_init+0x1606>
	return (void *)(pa + KERNBASE);
f0101fe4:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f0101fea:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101ff0:	8b 30                	mov    (%eax),%esi
f0101ff2:	83 e6 01             	and    $0x1,%esi
f0101ff5:	0f 85 13 09 00 00    	jne    f010290e <mem_init+0x161f>
	for(i=0; i<NPTENTRIES; i++)
f0101ffb:	83 c0 04             	add    $0x4,%eax
f0101ffe:	39 c2                	cmp    %eax,%edx
f0102000:	75 ee                	jne    f0101ff0 <mem_init+0xd01>
	kern_pgdir[0] = 0;
f0102002:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102005:	8b 83 10 1a 00 00    	mov    0x1a10(%ebx),%eax
f010200b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102011:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102014:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010201a:	8b 55 c8             	mov    -0x38(%ebp),%edx
f010201d:	89 93 20 1a 00 00    	mov    %edx,0x1a20(%ebx)

	// free the pages we took
	page_free(pp0);
f0102023:	83 ec 0c             	sub    $0xc,%esp
f0102026:	50                   	push   %eax
f0102027:	e8 f0 ef ff ff       	call   f010101c <page_free>
	page_free(pp1);
f010202c:	89 3c 24             	mov    %edi,(%esp)
f010202f:	e8 e8 ef ff ff       	call   f010101c <page_free>
	page_free(pp2);
f0102034:	83 c4 04             	add    $0x4,%esp
f0102037:	ff 75 d0             	push   -0x30(%ebp)
f010203a:	e8 dd ef ff ff       	call   f010101c <page_free>

	cprintf("check_page() succeeded!\n");
f010203f:	8d 83 f3 61 f8 ff    	lea    -0x79e0d(%ebx),%eax
f0102045:	89 04 24             	mov    %eax,(%esp)
f0102048:	e8 c8 18 00 00       	call   f0103915 <cprintf>
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f010204d:	8b 83 0c 1a 00 00    	mov    0x1a0c(%ebx),%eax
	if ((uint32_t)kva < KERNBASE)
f0102053:	83 c4 10             	add    $0x10,%esp
f0102056:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010205b:	0f 86 cf 08 00 00    	jbe    f0102930 <mem_init+0x1641>
f0102061:	83 ec 08             	sub    $0x8,%esp
f0102064:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102066:	05 00 00 00 10       	add    $0x10000000,%eax
f010206b:	50                   	push   %eax
f010206c:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102071:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102076:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102079:	8b 87 10 1a 00 00    	mov    0x1a10(%edi),%eax
f010207f:	e8 c3 f0 ff ff       	call   f0101147 <boot_map_region>
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);
f0102084:	c7 c0 54 13 18 f0    	mov    $0xf0181354,%eax
f010208a:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010208c:	83 c4 10             	add    $0x10,%esp
f010208f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102094:	0f 86 b2 08 00 00    	jbe    f010294c <mem_init+0x165d>
f010209a:	83 ec 08             	sub    $0x8,%esp
f010209d:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f010209f:	05 00 00 00 10       	add    $0x10000000,%eax
f01020a4:	50                   	push   %eax
f01020a5:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01020aa:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01020af:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01020b2:	8b 87 10 1a 00 00    	mov    0x1a10(%edi),%eax
f01020b8:	e8 8a f0 ff ff       	call   f0101147 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f01020bd:	c7 c0 00 30 11 f0    	mov    $0xf0113000,%eax
f01020c3:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01020c6:	83 c4 10             	add    $0x10,%esp
f01020c9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020ce:	0f 86 94 08 00 00    	jbe    f0102968 <mem_init+0x1679>
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01020d4:	83 ec 08             	sub    $0x8,%esp
f01020d7:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f01020d9:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01020dc:	05 00 00 00 10       	add    $0x10000000,%eax
f01020e1:	50                   	push   %eax
f01020e2:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01020e7:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01020ec:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01020ef:	8b 87 10 1a 00 00    	mov    0x1a10(%edi),%eax
f01020f5:	e8 4d f0 ff ff       	call   f0101147 <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
f01020fa:	83 c4 08             	add    $0x8,%esp
f01020fd:	6a 02                	push   $0x2
f01020ff:	6a 00                	push   $0x0
f0102101:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102106:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010210b:	8b 87 10 1a 00 00    	mov    0x1a10(%edi),%eax
f0102111:	e8 31 f0 ff ff       	call   f0101147 <boot_map_region>
	pgdir = kern_pgdir;
f0102116:	89 f9                	mov    %edi,%ecx
f0102118:	8b bf 10 1a 00 00    	mov    0x1a10(%edi),%edi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010211e:	8b 81 14 1a 00 00    	mov    0x1a14(%ecx),%eax
f0102124:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0102127:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010212e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102133:	89 c2                	mov    %eax,%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102135:	8b 81 0c 1a 00 00    	mov    0x1a0c(%ecx),%eax
f010213b:	89 45 bc             	mov    %eax,-0x44(%ebp)
f010213e:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0102144:	89 4d cc             	mov    %ecx,-0x34(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f0102147:	83 c4 10             	add    $0x10,%esp
f010214a:	89 f3                	mov    %esi,%ebx
f010214c:	89 75 c0             	mov    %esi,-0x40(%ebp)
f010214f:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102152:	89 d6                	mov    %edx,%esi
f0102154:	89 c7                	mov    %eax,%edi
f0102156:	e9 52 08 00 00       	jmp    f01029ad <mem_init+0x16be>
	assert(nfree == 0);
f010215b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010215e:	8d 83 1c 61 f8 ff    	lea    -0x79ee4(%ebx),%eax
f0102164:	50                   	push   %eax
f0102165:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010216b:	50                   	push   %eax
f010216c:	68 ec 02 00 00       	push   $0x2ec
f0102171:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102177:	50                   	push   %eax
f0102178:	e8 34 df ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f010217d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102180:	8d 83 2a 60 f8 ff    	lea    -0x79fd6(%ebx),%eax
f0102186:	50                   	push   %eax
f0102187:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010218d:	50                   	push   %eax
f010218e:	68 4a 03 00 00       	push   $0x34a
f0102193:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102199:	50                   	push   %eax
f010219a:	e8 12 df ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f010219f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01021a2:	8d 83 40 60 f8 ff    	lea    -0x79fc0(%ebx),%eax
f01021a8:	50                   	push   %eax
f01021a9:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01021af:	50                   	push   %eax
f01021b0:	68 4b 03 00 00       	push   $0x34b
f01021b5:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01021bb:	50                   	push   %eax
f01021bc:	e8 f0 de ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f01021c1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01021c4:	8d 83 56 60 f8 ff    	lea    -0x79faa(%ebx),%eax
f01021ca:	50                   	push   %eax
f01021cb:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01021d1:	50                   	push   %eax
f01021d2:	68 4c 03 00 00       	push   $0x34c
f01021d7:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01021dd:	50                   	push   %eax
f01021de:	e8 ce de ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f01021e3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01021e6:	8d 83 6c 60 f8 ff    	lea    -0x79f94(%ebx),%eax
f01021ec:	50                   	push   %eax
f01021ed:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01021f3:	50                   	push   %eax
f01021f4:	68 4f 03 00 00       	push   $0x34f
f01021f9:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01021ff:	50                   	push   %eax
f0102200:	e8 ac de ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0102205:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102208:	8d 83 c8 63 f8 ff    	lea    -0x79c38(%ebx),%eax
f010220e:	50                   	push   %eax
f010220f:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102215:	50                   	push   %eax
f0102216:	68 50 03 00 00       	push   $0x350
f010221b:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102221:	50                   	push   %eax
f0102222:	e8 8a de ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0102227:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010222a:	8d 83 d5 60 f8 ff    	lea    -0x79f2b(%ebx),%eax
f0102230:	50                   	push   %eax
f0102231:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102237:	50                   	push   %eax
f0102238:	68 57 03 00 00       	push   $0x357
f010223d:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102243:	50                   	push   %eax
f0102244:	e8 68 de ff ff       	call   f01000b1 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102249:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010224c:	8d 83 08 64 f8 ff    	lea    -0x79bf8(%ebx),%eax
f0102252:	50                   	push   %eax
f0102253:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102259:	50                   	push   %eax
f010225a:	68 5a 03 00 00       	push   $0x35a
f010225f:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102265:	50                   	push   %eax
f0102266:	e8 46 de ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010226b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010226e:	8d 83 40 64 f8 ff    	lea    -0x79bc0(%ebx),%eax
f0102274:	50                   	push   %eax
f0102275:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010227b:	50                   	push   %eax
f010227c:	68 5d 03 00 00       	push   $0x35d
f0102281:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102287:	50                   	push   %eax
f0102288:	e8 24 de ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010228d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102290:	8d 83 70 64 f8 ff    	lea    -0x79b90(%ebx),%eax
f0102296:	50                   	push   %eax
f0102297:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010229d:	50                   	push   %eax
f010229e:	68 61 03 00 00       	push   $0x361
f01022a3:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01022a9:	50                   	push   %eax
f01022aa:	e8 02 de ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01022af:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022b2:	8d 83 a0 64 f8 ff    	lea    -0x79b60(%ebx),%eax
f01022b8:	50                   	push   %eax
f01022b9:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01022bf:	50                   	push   %eax
f01022c0:	68 62 03 00 00       	push   $0x362
f01022c5:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01022cb:	50                   	push   %eax
f01022cc:	e8 e0 dd ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01022d1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022d4:	8d 83 c8 64 f8 ff    	lea    -0x79b38(%ebx),%eax
f01022da:	50                   	push   %eax
f01022db:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01022e1:	50                   	push   %eax
f01022e2:	68 63 03 00 00       	push   $0x363
f01022e7:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01022ed:	50                   	push   %eax
f01022ee:	e8 be dd ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f01022f3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022f6:	8d 83 27 61 f8 ff    	lea    -0x79ed9(%ebx),%eax
f01022fc:	50                   	push   %eax
f01022fd:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102303:	50                   	push   %eax
f0102304:	68 64 03 00 00       	push   $0x364
f0102309:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f010230f:	50                   	push   %eax
f0102310:	e8 9c dd ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f0102315:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102318:	8d 83 38 61 f8 ff    	lea    -0x79ec8(%ebx),%eax
f010231e:	50                   	push   %eax
f010231f:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102325:	50                   	push   %eax
f0102326:	68 65 03 00 00       	push   $0x365
f010232b:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102331:	50                   	push   %eax
f0102332:	e8 7a dd ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102337:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010233a:	8d 83 f8 64 f8 ff    	lea    -0x79b08(%ebx),%eax
f0102340:	50                   	push   %eax
f0102341:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102347:	50                   	push   %eax
f0102348:	68 68 03 00 00       	push   $0x368
f010234d:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102353:	50                   	push   %eax
f0102354:	e8 58 dd ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102359:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010235c:	8d 83 34 65 f8 ff    	lea    -0x79acc(%ebx),%eax
f0102362:	50                   	push   %eax
f0102363:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102369:	50                   	push   %eax
f010236a:	68 69 03 00 00       	push   $0x369
f010236f:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102375:	50                   	push   %eax
f0102376:	e8 36 dd ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f010237b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010237e:	8d 83 49 61 f8 ff    	lea    -0x79eb7(%ebx),%eax
f0102384:	50                   	push   %eax
f0102385:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010238b:	50                   	push   %eax
f010238c:	68 6a 03 00 00       	push   $0x36a
f0102391:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102397:	50                   	push   %eax
f0102398:	e8 14 dd ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f010239d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023a0:	8d 83 d5 60 f8 ff    	lea    -0x79f2b(%ebx),%eax
f01023a6:	50                   	push   %eax
f01023a7:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01023ad:	50                   	push   %eax
f01023ae:	68 6d 03 00 00       	push   $0x36d
f01023b3:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01023b9:	50                   	push   %eax
f01023ba:	e8 f2 dc ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01023bf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023c2:	8d 83 f8 64 f8 ff    	lea    -0x79b08(%ebx),%eax
f01023c8:	50                   	push   %eax
f01023c9:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01023cf:	50                   	push   %eax
f01023d0:	68 70 03 00 00       	push   $0x370
f01023d5:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01023db:	50                   	push   %eax
f01023dc:	e8 d0 dc ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01023e1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023e4:	8d 83 34 65 f8 ff    	lea    -0x79acc(%ebx),%eax
f01023ea:	50                   	push   %eax
f01023eb:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01023f1:	50                   	push   %eax
f01023f2:	68 71 03 00 00       	push   $0x371
f01023f7:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01023fd:	50                   	push   %eax
f01023fe:	e8 ae dc ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f0102403:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102406:	8d 83 49 61 f8 ff    	lea    -0x79eb7(%ebx),%eax
f010240c:	50                   	push   %eax
f010240d:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102413:	50                   	push   %eax
f0102414:	68 72 03 00 00       	push   $0x372
f0102419:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f010241f:	50                   	push   %eax
f0102420:	e8 8c dc ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0102425:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102428:	8d 83 d5 60 f8 ff    	lea    -0x79f2b(%ebx),%eax
f010242e:	50                   	push   %eax
f010242f:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102435:	50                   	push   %eax
f0102436:	68 76 03 00 00       	push   $0x376
f010243b:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102441:	50                   	push   %eax
f0102442:	e8 6a dc ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102447:	53                   	push   %ebx
f0102448:	89 cb                	mov    %ecx,%ebx
f010244a:	8d 81 3c 62 f8 ff    	lea    -0x79dc4(%ecx),%eax
f0102450:	50                   	push   %eax
f0102451:	68 79 03 00 00       	push   $0x379
f0102456:	8d 81 49 5f f8 ff    	lea    -0x7a0b7(%ecx),%eax
f010245c:	50                   	push   %eax
f010245d:	e8 4f dc ff ff       	call   f01000b1 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102462:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102465:	8d 83 64 65 f8 ff    	lea    -0x79a9c(%ebx),%eax
f010246b:	50                   	push   %eax
f010246c:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102472:	50                   	push   %eax
f0102473:	68 7a 03 00 00       	push   $0x37a
f0102478:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f010247e:	50                   	push   %eax
f010247f:	e8 2d dc ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102484:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102487:	8d 83 a4 65 f8 ff    	lea    -0x79a5c(%ebx),%eax
f010248d:	50                   	push   %eax
f010248e:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102494:	50                   	push   %eax
f0102495:	68 7d 03 00 00       	push   $0x37d
f010249a:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01024a0:	50                   	push   %eax
f01024a1:	e8 0b dc ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01024a6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024a9:	8d 83 34 65 f8 ff    	lea    -0x79acc(%ebx),%eax
f01024af:	50                   	push   %eax
f01024b0:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01024b6:	50                   	push   %eax
f01024b7:	68 7e 03 00 00       	push   $0x37e
f01024bc:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01024c2:	50                   	push   %eax
f01024c3:	e8 e9 db ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f01024c8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024cb:	8d 83 49 61 f8 ff    	lea    -0x79eb7(%ebx),%eax
f01024d1:	50                   	push   %eax
f01024d2:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01024d8:	50                   	push   %eax
f01024d9:	68 7f 03 00 00       	push   $0x37f
f01024de:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01024e4:	50                   	push   %eax
f01024e5:	e8 c7 db ff ff       	call   f01000b1 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01024ea:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024ed:	8d 83 e4 65 f8 ff    	lea    -0x79a1c(%ebx),%eax
f01024f3:	50                   	push   %eax
f01024f4:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01024fa:	50                   	push   %eax
f01024fb:	68 80 03 00 00       	push   $0x380
f0102500:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102506:	50                   	push   %eax
f0102507:	e8 a5 db ff ff       	call   f01000b1 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f010250c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010250f:	8d 83 5a 61 f8 ff    	lea    -0x79ea6(%ebx),%eax
f0102515:	50                   	push   %eax
f0102516:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010251c:	50                   	push   %eax
f010251d:	68 81 03 00 00       	push   $0x381
f0102522:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102528:	50                   	push   %eax
f0102529:	e8 83 db ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010252e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102531:	8d 83 f8 64 f8 ff    	lea    -0x79b08(%ebx),%eax
f0102537:	50                   	push   %eax
f0102538:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010253e:	50                   	push   %eax
f010253f:	68 84 03 00 00       	push   $0x384
f0102544:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f010254a:	50                   	push   %eax
f010254b:	e8 61 db ff ff       	call   f01000b1 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102550:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102553:	8d 83 18 66 f8 ff    	lea    -0x799e8(%ebx),%eax
f0102559:	50                   	push   %eax
f010255a:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102560:	50                   	push   %eax
f0102561:	68 85 03 00 00       	push   $0x385
f0102566:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f010256c:	50                   	push   %eax
f010256d:	e8 3f db ff ff       	call   f01000b1 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102572:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102575:	8d 83 4c 66 f8 ff    	lea    -0x799b4(%ebx),%eax
f010257b:	50                   	push   %eax
f010257c:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102582:	50                   	push   %eax
f0102583:	68 86 03 00 00       	push   $0x386
f0102588:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f010258e:	50                   	push   %eax
f010258f:	e8 1d db ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102594:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102597:	8d 83 84 66 f8 ff    	lea    -0x7997c(%ebx),%eax
f010259d:	50                   	push   %eax
f010259e:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01025a4:	50                   	push   %eax
f01025a5:	68 89 03 00 00       	push   $0x389
f01025aa:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01025b0:	50                   	push   %eax
f01025b1:	e8 fb da ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01025b6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025b9:	8d 83 bc 66 f8 ff    	lea    -0x79944(%ebx),%eax
f01025bf:	50                   	push   %eax
f01025c0:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01025c6:	50                   	push   %eax
f01025c7:	68 8c 03 00 00       	push   $0x38c
f01025cc:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01025d2:	50                   	push   %eax
f01025d3:	e8 d9 da ff ff       	call   f01000b1 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01025d8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025db:	8d 83 4c 66 f8 ff    	lea    -0x799b4(%ebx),%eax
f01025e1:	50                   	push   %eax
f01025e2:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01025e8:	50                   	push   %eax
f01025e9:	68 8d 03 00 00       	push   $0x38d
f01025ee:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01025f4:	50                   	push   %eax
f01025f5:	e8 b7 da ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01025fa:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025fd:	8d 83 f8 66 f8 ff    	lea    -0x79908(%ebx),%eax
f0102603:	50                   	push   %eax
f0102604:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010260a:	50                   	push   %eax
f010260b:	68 90 03 00 00       	push   $0x390
f0102610:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102616:	50                   	push   %eax
f0102617:	e8 95 da ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010261c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010261f:	8d 83 24 67 f8 ff    	lea    -0x798dc(%ebx),%eax
f0102625:	50                   	push   %eax
f0102626:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010262c:	50                   	push   %eax
f010262d:	68 91 03 00 00       	push   $0x391
f0102632:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102638:	50                   	push   %eax
f0102639:	e8 73 da ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 2);
f010263e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102641:	8d 83 70 61 f8 ff    	lea    -0x79e90(%ebx),%eax
f0102647:	50                   	push   %eax
f0102648:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010264e:	50                   	push   %eax
f010264f:	68 93 03 00 00       	push   $0x393
f0102654:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f010265a:	50                   	push   %eax
f010265b:	e8 51 da ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f0102660:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102663:	8d 83 81 61 f8 ff    	lea    -0x79e7f(%ebx),%eax
f0102669:	50                   	push   %eax
f010266a:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102670:	50                   	push   %eax
f0102671:	68 94 03 00 00       	push   $0x394
f0102676:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f010267c:	50                   	push   %eax
f010267d:	e8 2f da ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102682:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102685:	8d 83 54 67 f8 ff    	lea    -0x798ac(%ebx),%eax
f010268b:	50                   	push   %eax
f010268c:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102692:	50                   	push   %eax
f0102693:	68 97 03 00 00       	push   $0x397
f0102698:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f010269e:	50                   	push   %eax
f010269f:	e8 0d da ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01026a4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026a7:	8d 83 78 67 f8 ff    	lea    -0x79888(%ebx),%eax
f01026ad:	50                   	push   %eax
f01026ae:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01026b4:	50                   	push   %eax
f01026b5:	68 9b 03 00 00       	push   $0x39b
f01026ba:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01026c0:	50                   	push   %eax
f01026c1:	e8 eb d9 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01026c6:	89 cb                	mov    %ecx,%ebx
f01026c8:	8d 81 24 67 f8 ff    	lea    -0x798dc(%ecx),%eax
f01026ce:	50                   	push   %eax
f01026cf:	8d 81 6f 5f f8 ff    	lea    -0x7a091(%ecx),%eax
f01026d5:	50                   	push   %eax
f01026d6:	68 9c 03 00 00       	push   $0x39c
f01026db:	8d 81 49 5f f8 ff    	lea    -0x7a0b7(%ecx),%eax
f01026e1:	50                   	push   %eax
f01026e2:	e8 ca d9 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f01026e7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026ea:	8d 83 27 61 f8 ff    	lea    -0x79ed9(%ebx),%eax
f01026f0:	50                   	push   %eax
f01026f1:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01026f7:	50                   	push   %eax
f01026f8:	68 9d 03 00 00       	push   $0x39d
f01026fd:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102703:	50                   	push   %eax
f0102704:	e8 a8 d9 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f0102709:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010270c:	8d 83 81 61 f8 ff    	lea    -0x79e7f(%ebx),%eax
f0102712:	50                   	push   %eax
f0102713:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102719:	50                   	push   %eax
f010271a:	68 9e 03 00 00       	push   $0x39e
f010271f:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102725:	50                   	push   %eax
f0102726:	e8 86 d9 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f010272b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010272e:	8d 83 9c 67 f8 ff    	lea    -0x79864(%ebx),%eax
f0102734:	50                   	push   %eax
f0102735:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010273b:	50                   	push   %eax
f010273c:	68 a1 03 00 00       	push   $0x3a1
f0102741:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102747:	50                   	push   %eax
f0102748:	e8 64 d9 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref);
f010274d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102750:	8d 83 92 61 f8 ff    	lea    -0x79e6e(%ebx),%eax
f0102756:	50                   	push   %eax
f0102757:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010275d:	50                   	push   %eax
f010275e:	68 a2 03 00 00       	push   $0x3a2
f0102763:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102769:	50                   	push   %eax
f010276a:	e8 42 d9 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_link == NULL);
f010276f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102772:	8d 83 9e 61 f8 ff    	lea    -0x79e62(%ebx),%eax
f0102778:	50                   	push   %eax
f0102779:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010277f:	50                   	push   %eax
f0102780:	68 a3 03 00 00       	push   $0x3a3
f0102785:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f010278b:	50                   	push   %eax
f010278c:	e8 20 d9 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102791:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102794:	8d 83 78 67 f8 ff    	lea    -0x79888(%ebx),%eax
f010279a:	50                   	push   %eax
f010279b:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01027a1:	50                   	push   %eax
f01027a2:	68 a7 03 00 00       	push   $0x3a7
f01027a7:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01027ad:	50                   	push   %eax
f01027ae:	e8 fe d8 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01027b3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027b6:	8d 83 d4 67 f8 ff    	lea    -0x7982c(%ebx),%eax
f01027bc:	50                   	push   %eax
f01027bd:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01027c3:	50                   	push   %eax
f01027c4:	68 a8 03 00 00       	push   $0x3a8
f01027c9:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01027cf:	50                   	push   %eax
f01027d0:	e8 dc d8 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 0);
f01027d5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027d8:	8d 83 b3 61 f8 ff    	lea    -0x79e4d(%ebx),%eax
f01027de:	50                   	push   %eax
f01027df:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01027e5:	50                   	push   %eax
f01027e6:	68 a9 03 00 00       	push   $0x3a9
f01027eb:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01027f1:	50                   	push   %eax
f01027f2:	e8 ba d8 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f01027f7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027fa:	8d 83 81 61 f8 ff    	lea    -0x79e7f(%ebx),%eax
f0102800:	50                   	push   %eax
f0102801:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102807:	50                   	push   %eax
f0102808:	68 aa 03 00 00       	push   $0x3aa
f010280d:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102813:	50                   	push   %eax
f0102814:	e8 98 d8 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f0102819:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010281c:	8d 83 fc 67 f8 ff    	lea    -0x79804(%ebx),%eax
f0102822:	50                   	push   %eax
f0102823:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102829:	50                   	push   %eax
f010282a:	68 ad 03 00 00       	push   $0x3ad
f010282f:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102835:	50                   	push   %eax
f0102836:	e8 76 d8 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f010283b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010283e:	8d 83 d5 60 f8 ff    	lea    -0x79f2b(%ebx),%eax
f0102844:	50                   	push   %eax
f0102845:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010284b:	50                   	push   %eax
f010284c:	68 b0 03 00 00       	push   $0x3b0
f0102851:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102857:	50                   	push   %eax
f0102858:	e8 54 d8 ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010285d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102860:	8d 83 a0 64 f8 ff    	lea    -0x79b60(%ebx),%eax
f0102866:	50                   	push   %eax
f0102867:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010286d:	50                   	push   %eax
f010286e:	68 b3 03 00 00       	push   $0x3b3
f0102873:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102879:	50                   	push   %eax
f010287a:	e8 32 d8 ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f010287f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102882:	8d 83 38 61 f8 ff    	lea    -0x79ec8(%ebx),%eax
f0102888:	50                   	push   %eax
f0102889:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010288f:	50                   	push   %eax
f0102890:	68 b5 03 00 00       	push   $0x3b5
f0102895:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f010289b:	50                   	push   %eax
f010289c:	e8 10 d8 ff ff       	call   f01000b1 <_panic>
f01028a1:	52                   	push   %edx
f01028a2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028a5:	8d 83 3c 62 f8 ff    	lea    -0x79dc4(%ebx),%eax
f01028ab:	50                   	push   %eax
f01028ac:	68 bc 03 00 00       	push   $0x3bc
f01028b1:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01028b7:	50                   	push   %eax
f01028b8:	e8 f4 d7 ff ff       	call   f01000b1 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01028bd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028c0:	8d 83 c4 61 f8 ff    	lea    -0x79e3c(%ebx),%eax
f01028c6:	50                   	push   %eax
f01028c7:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01028cd:	50                   	push   %eax
f01028ce:	68 bd 03 00 00       	push   $0x3bd
f01028d3:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01028d9:	50                   	push   %eax
f01028da:	e8 d2 d7 ff ff       	call   f01000b1 <_panic>
f01028df:	52                   	push   %edx
f01028e0:	8d 83 3c 62 f8 ff    	lea    -0x79dc4(%ebx),%eax
f01028e6:	50                   	push   %eax
f01028e7:	6a 56                	push   $0x56
f01028e9:	8d 83 55 5f f8 ff    	lea    -0x7a0ab(%ebx),%eax
f01028ef:	50                   	push   %eax
f01028f0:	e8 bc d7 ff ff       	call   f01000b1 <_panic>
f01028f5:	52                   	push   %edx
f01028f6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028f9:	8d 83 3c 62 f8 ff    	lea    -0x79dc4(%ebx),%eax
f01028ff:	50                   	push   %eax
f0102900:	6a 56                	push   $0x56
f0102902:	8d 83 55 5f f8 ff    	lea    -0x7a0ab(%ebx),%eax
f0102908:	50                   	push   %eax
f0102909:	e8 a3 d7 ff ff       	call   f01000b1 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f010290e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102911:	8d 83 dc 61 f8 ff    	lea    -0x79e24(%ebx),%eax
f0102917:	50                   	push   %eax
f0102918:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010291e:	50                   	push   %eax
f010291f:	68 c7 03 00 00       	push   $0x3c7
f0102924:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f010292a:	50                   	push   %eax
f010292b:	e8 81 d7 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102930:	50                   	push   %eax
f0102931:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102934:	8d 83 a4 63 f8 ff    	lea    -0x79c5c(%ebx),%eax
f010293a:	50                   	push   %eax
f010293b:	68 bb 00 00 00       	push   $0xbb
f0102940:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102946:	50                   	push   %eax
f0102947:	e8 65 d7 ff ff       	call   f01000b1 <_panic>
f010294c:	50                   	push   %eax
f010294d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102950:	8d 83 a4 63 f8 ff    	lea    -0x79c5c(%ebx),%eax
f0102956:	50                   	push   %eax
f0102957:	68 c4 00 00 00       	push   $0xc4
f010295c:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102962:	50                   	push   %eax
f0102963:	e8 49 d7 ff ff       	call   f01000b1 <_panic>
f0102968:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010296b:	ff b3 fc ff ff ff    	push   -0x4(%ebx)
f0102971:	8d 83 a4 63 f8 ff    	lea    -0x79c5c(%ebx),%eax
f0102977:	50                   	push   %eax
f0102978:	68 d1 00 00 00       	push   $0xd1
f010297d:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102983:	50                   	push   %eax
f0102984:	e8 28 d7 ff ff       	call   f01000b1 <_panic>
f0102989:	ff 75 bc             	push   -0x44(%ebp)
f010298c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010298f:	8d 83 a4 63 f8 ff    	lea    -0x79c5c(%ebx),%eax
f0102995:	50                   	push   %eax
f0102996:	68 04 03 00 00       	push   $0x304
f010299b:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01029a1:	50                   	push   %eax
f01029a2:	e8 0a d7 ff ff       	call   f01000b1 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f01029a7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01029ad:	39 de                	cmp    %ebx,%esi
f01029af:	76 42                	jbe    f01029f3 <mem_init+0x1704>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01029b1:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01029b7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01029ba:	e8 2f e1 ff ff       	call   f0100aee <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f01029bf:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f01029c5:	76 c2                	jbe    f0102989 <mem_init+0x169a>
f01029c7:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01029ca:	8d 14 0b             	lea    (%ebx,%ecx,1),%edx
f01029cd:	39 c2                	cmp    %eax,%edx
f01029cf:	74 d6                	je     f01029a7 <mem_init+0x16b8>
f01029d1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029d4:	8d 83 20 68 f8 ff    	lea    -0x797e0(%ebx),%eax
f01029da:	50                   	push   %eax
f01029db:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f01029e1:	50                   	push   %eax
f01029e2:	68 04 03 00 00       	push   $0x304
f01029e7:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f01029ed:	50                   	push   %eax
f01029ee:	e8 be d6 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01029f3:	8b 75 c0             	mov    -0x40(%ebp),%esi
f01029f6:	8b 7d d0             	mov    -0x30(%ebp),%edi
f01029f9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029fc:	c7 c0 54 13 18 f0    	mov    $0xf0181354,%eax
f0102a02:	8b 00                	mov    (%eax),%eax
f0102a04:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0102a07:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0102a0c:	8d 88 00 00 40 21    	lea    0x21400000(%eax),%ecx
f0102a12:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0102a15:	89 75 cc             	mov    %esi,-0x34(%ebp)
f0102a18:	89 c6                	mov    %eax,%esi
f0102a1a:	89 da                	mov    %ebx,%edx
f0102a1c:	89 f8                	mov    %edi,%eax
f0102a1e:	e8 cb e0 ff ff       	call   f0100aee <check_va2pa>
f0102a23:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102a29:	76 45                	jbe    f0102a70 <mem_init+0x1781>
f0102a2b:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102a2e:	8d 14 19             	lea    (%ecx,%ebx,1),%edx
f0102a31:	39 c2                	cmp    %eax,%edx
f0102a33:	75 59                	jne    f0102a8e <mem_init+0x179f>
	for (i = 0; i < n; i += PGSIZE)
f0102a35:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102a3b:	81 fb 00 80 c1 ee    	cmp    $0xeec18000,%ebx
f0102a41:	75 d7                	jne    f0102a1a <mem_init+0x172b>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a43:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0102a46:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0102a49:	c1 e0 0c             	shl    $0xc,%eax
f0102a4c:	89 f3                	mov    %esi,%ebx
f0102a4e:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0102a51:	89 c6                	mov    %eax,%esi
f0102a53:	39 f3                	cmp    %esi,%ebx
f0102a55:	73 7b                	jae    f0102ad2 <mem_init+0x17e3>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102a57:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102a5d:	89 f8                	mov    %edi,%eax
f0102a5f:	e8 8a e0 ff ff       	call   f0100aee <check_va2pa>
f0102a64:	39 c3                	cmp    %eax,%ebx
f0102a66:	75 48                	jne    f0102ab0 <mem_init+0x17c1>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a68:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102a6e:	eb e3                	jmp    f0102a53 <mem_init+0x1764>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a70:	ff 75 c0             	push   -0x40(%ebp)
f0102a73:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a76:	8d 83 a4 63 f8 ff    	lea    -0x79c5c(%ebx),%eax
f0102a7c:	50                   	push   %eax
f0102a7d:	68 09 03 00 00       	push   $0x309
f0102a82:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102a88:	50                   	push   %eax
f0102a89:	e8 23 d6 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102a8e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a91:	8d 83 54 68 f8 ff    	lea    -0x797ac(%ebx),%eax
f0102a97:	50                   	push   %eax
f0102a98:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102a9e:	50                   	push   %eax
f0102a9f:	68 09 03 00 00       	push   $0x309
f0102aa4:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102aaa:	50                   	push   %eax
f0102aab:	e8 01 d6 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102ab0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ab3:	8d 83 88 68 f8 ff    	lea    -0x79778(%ebx),%eax
f0102ab9:	50                   	push   %eax
f0102aba:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102ac0:	50                   	push   %eax
f0102ac1:	68 0d 03 00 00       	push   $0x30d
f0102ac6:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102acc:	50                   	push   %eax
f0102acd:	e8 df d5 ff ff       	call   f01000b1 <_panic>
f0102ad2:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102ad7:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102ada:	05 00 80 00 20       	add    $0x20008000,%eax
f0102adf:	89 c6                	mov    %eax,%esi
f0102ae1:	89 da                	mov    %ebx,%edx
f0102ae3:	89 f8                	mov    %edi,%eax
f0102ae5:	e8 04 e0 ff ff       	call   f0100aee <check_va2pa>
f0102aea:	89 c2                	mov    %eax,%edx
f0102aec:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
f0102aef:	39 c2                	cmp    %eax,%edx
f0102af1:	75 44                	jne    f0102b37 <mem_init+0x1848>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102af3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102af9:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102aff:	75 e0                	jne    f0102ae1 <mem_init+0x17f2>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102b01:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102b04:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102b09:	89 f8                	mov    %edi,%eax
f0102b0b:	e8 de df ff ff       	call   f0100aee <check_va2pa>
f0102b10:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102b13:	74 71                	je     f0102b86 <mem_init+0x1897>
f0102b15:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b18:	8d 83 f8 68 f8 ff    	lea    -0x79708(%ebx),%eax
f0102b1e:	50                   	push   %eax
f0102b1f:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102b25:	50                   	push   %eax
f0102b26:	68 12 03 00 00       	push   $0x312
f0102b2b:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102b31:	50                   	push   %eax
f0102b32:	e8 7a d5 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102b37:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b3a:	8d 83 b0 68 f8 ff    	lea    -0x79750(%ebx),%eax
f0102b40:	50                   	push   %eax
f0102b41:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102b47:	50                   	push   %eax
f0102b48:	68 11 03 00 00       	push   $0x311
f0102b4d:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102b53:	50                   	push   %eax
f0102b54:	e8 58 d5 ff ff       	call   f01000b1 <_panic>
		switch (i) {
f0102b59:	81 fe bf 03 00 00    	cmp    $0x3bf,%esi
f0102b5f:	75 25                	jne    f0102b86 <mem_init+0x1897>
			assert(pgdir[i] & PTE_P);
f0102b61:	f6 04 b7 01          	testb  $0x1,(%edi,%esi,4)
f0102b65:	74 4f                	je     f0102bb6 <mem_init+0x18c7>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b67:	83 c6 01             	add    $0x1,%esi
f0102b6a:	81 fe ff 03 00 00    	cmp    $0x3ff,%esi
f0102b70:	0f 87 b1 00 00 00    	ja     f0102c27 <mem_init+0x1938>
		switch (i) {
f0102b76:	81 fe bd 03 00 00    	cmp    $0x3bd,%esi
f0102b7c:	77 db                	ja     f0102b59 <mem_init+0x186a>
f0102b7e:	81 fe ba 03 00 00    	cmp    $0x3ba,%esi
f0102b84:	77 db                	ja     f0102b61 <mem_init+0x1872>
			if (i >= PDX(KERNBASE)) {
f0102b86:	81 fe bf 03 00 00    	cmp    $0x3bf,%esi
f0102b8c:	77 4a                	ja     f0102bd8 <mem_init+0x18e9>
				assert(pgdir[i] == 0);
f0102b8e:	83 3c b7 00          	cmpl   $0x0,(%edi,%esi,4)
f0102b92:	74 d3                	je     f0102b67 <mem_init+0x1878>
f0102b94:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b97:	8d 83 2e 62 f8 ff    	lea    -0x79dd2(%ebx),%eax
f0102b9d:	50                   	push   %eax
f0102b9e:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102ba4:	50                   	push   %eax
f0102ba5:	68 22 03 00 00       	push   $0x322
f0102baa:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102bb0:	50                   	push   %eax
f0102bb1:	e8 fb d4 ff ff       	call   f01000b1 <_panic>
			assert(pgdir[i] & PTE_P);
f0102bb6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bb9:	8d 83 0c 62 f8 ff    	lea    -0x79df4(%ebx),%eax
f0102bbf:	50                   	push   %eax
f0102bc0:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102bc6:	50                   	push   %eax
f0102bc7:	68 1b 03 00 00       	push   $0x31b
f0102bcc:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102bd2:	50                   	push   %eax
f0102bd3:	e8 d9 d4 ff ff       	call   f01000b1 <_panic>
				assert(pgdir[i] & PTE_P);
f0102bd8:	8b 04 b7             	mov    (%edi,%esi,4),%eax
f0102bdb:	a8 01                	test   $0x1,%al
f0102bdd:	74 26                	je     f0102c05 <mem_init+0x1916>
				assert(pgdir[i] & PTE_W);
f0102bdf:	a8 02                	test   $0x2,%al
f0102be1:	75 84                	jne    f0102b67 <mem_init+0x1878>
f0102be3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102be6:	8d 83 1d 62 f8 ff    	lea    -0x79de3(%ebx),%eax
f0102bec:	50                   	push   %eax
f0102bed:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102bf3:	50                   	push   %eax
f0102bf4:	68 20 03 00 00       	push   $0x320
f0102bf9:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102bff:	50                   	push   %eax
f0102c00:	e8 ac d4 ff ff       	call   f01000b1 <_panic>
				assert(pgdir[i] & PTE_P);
f0102c05:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c08:	8d 83 0c 62 f8 ff    	lea    -0x79df4(%ebx),%eax
f0102c0e:	50                   	push   %eax
f0102c0f:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102c15:	50                   	push   %eax
f0102c16:	68 1f 03 00 00       	push   $0x31f
f0102c1b:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102c21:	50                   	push   %eax
f0102c22:	e8 8a d4 ff ff       	call   f01000b1 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102c27:	83 ec 0c             	sub    $0xc,%esp
f0102c2a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c2d:	8d 83 28 69 f8 ff    	lea    -0x796d8(%ebx),%eax
f0102c33:	50                   	push   %eax
f0102c34:	e8 dc 0c 00 00       	call   f0103915 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102c39:	8b 83 10 1a 00 00    	mov    0x1a10(%ebx),%eax
	if ((uint32_t)kva < KERNBASE)
f0102c3f:	83 c4 10             	add    $0x10,%esp
f0102c42:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c47:	0f 86 2c 02 00 00    	jbe    f0102e79 <mem_init+0x1b8a>
	return (physaddr_t)kva - KERNBASE;
f0102c4d:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102c52:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102c55:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c5a:	e8 0b df ff ff       	call   f0100b6a <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102c5f:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102c62:	83 e0 f3             	and    $0xfffffff3,%eax
f0102c65:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102c6a:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102c6d:	83 ec 0c             	sub    $0xc,%esp
f0102c70:	6a 00                	push   $0x0
f0102c72:	e8 20 e3 ff ff       	call   f0100f97 <page_alloc>
f0102c77:	89 c6                	mov    %eax,%esi
f0102c79:	83 c4 10             	add    $0x10,%esp
f0102c7c:	85 c0                	test   %eax,%eax
f0102c7e:	0f 84 11 02 00 00    	je     f0102e95 <mem_init+0x1ba6>
	assert((pp1 = page_alloc(0)));
f0102c84:	83 ec 0c             	sub    $0xc,%esp
f0102c87:	6a 00                	push   $0x0
f0102c89:	e8 09 e3 ff ff       	call   f0100f97 <page_alloc>
f0102c8e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102c91:	83 c4 10             	add    $0x10,%esp
f0102c94:	85 c0                	test   %eax,%eax
f0102c96:	0f 84 1b 02 00 00    	je     f0102eb7 <mem_init+0x1bc8>
	assert((pp2 = page_alloc(0)));
f0102c9c:	83 ec 0c             	sub    $0xc,%esp
f0102c9f:	6a 00                	push   $0x0
f0102ca1:	e8 f1 e2 ff ff       	call   f0100f97 <page_alloc>
f0102ca6:	89 c7                	mov    %eax,%edi
f0102ca8:	83 c4 10             	add    $0x10,%esp
f0102cab:	85 c0                	test   %eax,%eax
f0102cad:	0f 84 26 02 00 00    	je     f0102ed9 <mem_init+0x1bea>
	page_free(pp0);
f0102cb3:	83 ec 0c             	sub    $0xc,%esp
f0102cb6:	56                   	push   %esi
f0102cb7:	e8 60 e3 ff ff       	call   f010101c <page_free>
	return (pp - pages) << PGSHIFT;
f0102cbc:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102cbf:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102cc2:	2b 81 0c 1a 00 00    	sub    0x1a0c(%ecx),%eax
f0102cc8:	c1 f8 03             	sar    $0x3,%eax
f0102ccb:	89 c2                	mov    %eax,%edx
f0102ccd:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102cd0:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102cd5:	83 c4 10             	add    $0x10,%esp
f0102cd8:	3b 81 14 1a 00 00    	cmp    0x1a14(%ecx),%eax
f0102cde:	0f 83 17 02 00 00    	jae    f0102efb <mem_init+0x1c0c>
	memset(page2kva(pp1), 1, PGSIZE);
f0102ce4:	83 ec 04             	sub    $0x4,%esp
f0102ce7:	68 00 10 00 00       	push   $0x1000
f0102cec:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102cee:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102cf4:	52                   	push   %edx
f0102cf5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cf8:	e8 5f 22 00 00       	call   f0104f5c <memset>
	return (pp - pages) << PGSHIFT;
f0102cfd:	89 f8                	mov    %edi,%eax
f0102cff:	2b 83 0c 1a 00 00    	sub    0x1a0c(%ebx),%eax
f0102d05:	c1 f8 03             	sar    $0x3,%eax
f0102d08:	89 c2                	mov    %eax,%edx
f0102d0a:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102d0d:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102d12:	83 c4 10             	add    $0x10,%esp
f0102d15:	3b 83 14 1a 00 00    	cmp    0x1a14(%ebx),%eax
f0102d1b:	0f 83 f2 01 00 00    	jae    f0102f13 <mem_init+0x1c24>
	memset(page2kva(pp2), 2, PGSIZE);
f0102d21:	83 ec 04             	sub    $0x4,%esp
f0102d24:	68 00 10 00 00       	push   $0x1000
f0102d29:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102d2b:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102d31:	52                   	push   %edx
f0102d32:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d35:	e8 22 22 00 00       	call   f0104f5c <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102d3a:	6a 02                	push   $0x2
f0102d3c:	68 00 10 00 00       	push   $0x1000
f0102d41:	ff 75 d0             	push   -0x30(%ebp)
f0102d44:	ff b3 10 1a 00 00    	push   0x1a10(%ebx)
f0102d4a:	e8 20 e5 ff ff       	call   f010126f <page_insert>
	assert(pp1->pp_ref == 1);
f0102d4f:	83 c4 20             	add    $0x20,%esp
f0102d52:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102d55:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102d5a:	0f 85 cc 01 00 00    	jne    f0102f2c <mem_init+0x1c3d>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102d60:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102d67:	01 01 01 
f0102d6a:	0f 85 de 01 00 00    	jne    f0102f4e <mem_init+0x1c5f>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102d70:	6a 02                	push   $0x2
f0102d72:	68 00 10 00 00       	push   $0x1000
f0102d77:	57                   	push   %edi
f0102d78:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d7b:	ff b0 10 1a 00 00    	push   0x1a10(%eax)
f0102d81:	e8 e9 e4 ff ff       	call   f010126f <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102d86:	83 c4 10             	add    $0x10,%esp
f0102d89:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102d90:	02 02 02 
f0102d93:	0f 85 d7 01 00 00    	jne    f0102f70 <mem_init+0x1c81>
	assert(pp2->pp_ref == 1);
f0102d99:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102d9e:	0f 85 ee 01 00 00    	jne    f0102f92 <mem_init+0x1ca3>
	assert(pp1->pp_ref == 0);
f0102da4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102da7:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102dac:	0f 85 02 02 00 00    	jne    f0102fb4 <mem_init+0x1cc5>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102db2:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102db9:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102dbc:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102dbf:	89 f8                	mov    %edi,%eax
f0102dc1:	2b 81 0c 1a 00 00    	sub    0x1a0c(%ecx),%eax
f0102dc7:	c1 f8 03             	sar    $0x3,%eax
f0102dca:	89 c2                	mov    %eax,%edx
f0102dcc:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102dcf:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102dd4:	3b 81 14 1a 00 00    	cmp    0x1a14(%ecx),%eax
f0102dda:	0f 83 f6 01 00 00    	jae    f0102fd6 <mem_init+0x1ce7>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102de0:	81 ba 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%edx)
f0102de7:	03 03 03 
f0102dea:	0f 85 fe 01 00 00    	jne    f0102fee <mem_init+0x1cff>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102df0:	83 ec 08             	sub    $0x8,%esp
f0102df3:	68 00 10 00 00       	push   $0x1000
f0102df8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102dfb:	ff b0 10 1a 00 00    	push   0x1a10(%eax)
f0102e01:	e8 2e e4 ff ff       	call   f0101234 <page_remove>
	assert(pp2->pp_ref == 0);
f0102e06:	83 c4 10             	add    $0x10,%esp
f0102e09:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102e0e:	0f 85 fc 01 00 00    	jne    f0103010 <mem_init+0x1d21>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102e14:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e17:	8b 88 10 1a 00 00    	mov    0x1a10(%eax),%ecx
f0102e1d:	8b 11                	mov    (%ecx),%edx
f0102e1f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102e25:	89 f7                	mov    %esi,%edi
f0102e27:	2b b8 0c 1a 00 00    	sub    0x1a0c(%eax),%edi
f0102e2d:	89 f8                	mov    %edi,%eax
f0102e2f:	c1 f8 03             	sar    $0x3,%eax
f0102e32:	c1 e0 0c             	shl    $0xc,%eax
f0102e35:	39 c2                	cmp    %eax,%edx
f0102e37:	0f 85 f5 01 00 00    	jne    f0103032 <mem_init+0x1d43>
	kern_pgdir[0] = 0;
f0102e3d:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102e43:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102e48:	0f 85 06 02 00 00    	jne    f0103054 <mem_init+0x1d65>
	pp0->pp_ref = 0;
f0102e4e:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102e54:	83 ec 0c             	sub    $0xc,%esp
f0102e57:	56                   	push   %esi
f0102e58:	e8 bf e1 ff ff       	call   f010101c <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102e5d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e60:	8d 83 bc 69 f8 ff    	lea    -0x79644(%ebx),%eax
f0102e66:	89 04 24             	mov    %eax,(%esp)
f0102e69:	e8 a7 0a 00 00       	call   f0103915 <cprintf>
}
f0102e6e:	83 c4 10             	add    $0x10,%esp
f0102e71:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e74:	5b                   	pop    %ebx
f0102e75:	5e                   	pop    %esi
f0102e76:	5f                   	pop    %edi
f0102e77:	5d                   	pop    %ebp
f0102e78:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e79:	50                   	push   %eax
f0102e7a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e7d:	8d 83 a4 63 f8 ff    	lea    -0x79c5c(%ebx),%eax
f0102e83:	50                   	push   %eax
f0102e84:	68 e7 00 00 00       	push   $0xe7
f0102e89:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102e8f:	50                   	push   %eax
f0102e90:	e8 1c d2 ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f0102e95:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e98:	8d 83 2a 60 f8 ff    	lea    -0x79fd6(%ebx),%eax
f0102e9e:	50                   	push   %eax
f0102e9f:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102ea5:	50                   	push   %eax
f0102ea6:	68 e2 03 00 00       	push   $0x3e2
f0102eab:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102eb1:	50                   	push   %eax
f0102eb2:	e8 fa d1 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f0102eb7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102eba:	8d 83 40 60 f8 ff    	lea    -0x79fc0(%ebx),%eax
f0102ec0:	50                   	push   %eax
f0102ec1:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102ec7:	50                   	push   %eax
f0102ec8:	68 e3 03 00 00       	push   $0x3e3
f0102ecd:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102ed3:	50                   	push   %eax
f0102ed4:	e8 d8 d1 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f0102ed9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102edc:	8d 83 56 60 f8 ff    	lea    -0x79faa(%ebx),%eax
f0102ee2:	50                   	push   %eax
f0102ee3:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102ee9:	50                   	push   %eax
f0102eea:	68 e4 03 00 00       	push   $0x3e4
f0102eef:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102ef5:	50                   	push   %eax
f0102ef6:	e8 b6 d1 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102efb:	52                   	push   %edx
f0102efc:	89 cb                	mov    %ecx,%ebx
f0102efe:	8d 81 3c 62 f8 ff    	lea    -0x79dc4(%ecx),%eax
f0102f04:	50                   	push   %eax
f0102f05:	6a 56                	push   $0x56
f0102f07:	8d 81 55 5f f8 ff    	lea    -0x7a0ab(%ecx),%eax
f0102f0d:	50                   	push   %eax
f0102f0e:	e8 9e d1 ff ff       	call   f01000b1 <_panic>
f0102f13:	52                   	push   %edx
f0102f14:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f17:	8d 83 3c 62 f8 ff    	lea    -0x79dc4(%ebx),%eax
f0102f1d:	50                   	push   %eax
f0102f1e:	6a 56                	push   $0x56
f0102f20:	8d 83 55 5f f8 ff    	lea    -0x7a0ab(%ebx),%eax
f0102f26:	50                   	push   %eax
f0102f27:	e8 85 d1 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f0102f2c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f2f:	8d 83 27 61 f8 ff    	lea    -0x79ed9(%ebx),%eax
f0102f35:	50                   	push   %eax
f0102f36:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102f3c:	50                   	push   %eax
f0102f3d:	68 e9 03 00 00       	push   $0x3e9
f0102f42:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102f48:	50                   	push   %eax
f0102f49:	e8 63 d1 ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102f4e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f51:	8d 83 48 69 f8 ff    	lea    -0x796b8(%ebx),%eax
f0102f57:	50                   	push   %eax
f0102f58:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102f5e:	50                   	push   %eax
f0102f5f:	68 ea 03 00 00       	push   $0x3ea
f0102f64:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102f6a:	50                   	push   %eax
f0102f6b:	e8 41 d1 ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102f70:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f73:	8d 83 6c 69 f8 ff    	lea    -0x79694(%ebx),%eax
f0102f79:	50                   	push   %eax
f0102f7a:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102f80:	50                   	push   %eax
f0102f81:	68 ec 03 00 00       	push   $0x3ec
f0102f86:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102f8c:	50                   	push   %eax
f0102f8d:	e8 1f d1 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f0102f92:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f95:	8d 83 49 61 f8 ff    	lea    -0x79eb7(%ebx),%eax
f0102f9b:	50                   	push   %eax
f0102f9c:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102fa2:	50                   	push   %eax
f0102fa3:	68 ed 03 00 00       	push   $0x3ed
f0102fa8:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102fae:	50                   	push   %eax
f0102faf:	e8 fd d0 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 0);
f0102fb4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fb7:	8d 83 b3 61 f8 ff    	lea    -0x79e4d(%ebx),%eax
f0102fbd:	50                   	push   %eax
f0102fbe:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102fc4:	50                   	push   %eax
f0102fc5:	68 ee 03 00 00       	push   $0x3ee
f0102fca:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0102fd0:	50                   	push   %eax
f0102fd1:	e8 db d0 ff ff       	call   f01000b1 <_panic>
f0102fd6:	52                   	push   %edx
f0102fd7:	89 cb                	mov    %ecx,%ebx
f0102fd9:	8d 81 3c 62 f8 ff    	lea    -0x79dc4(%ecx),%eax
f0102fdf:	50                   	push   %eax
f0102fe0:	6a 56                	push   $0x56
f0102fe2:	8d 81 55 5f f8 ff    	lea    -0x7a0ab(%ecx),%eax
f0102fe8:	50                   	push   %eax
f0102fe9:	e8 c3 d0 ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102fee:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ff1:	8d 83 90 69 f8 ff    	lea    -0x79670(%ebx),%eax
f0102ff7:	50                   	push   %eax
f0102ff8:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0102ffe:	50                   	push   %eax
f0102fff:	68 f0 03 00 00       	push   $0x3f0
f0103004:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f010300a:	50                   	push   %eax
f010300b:	e8 a1 d0 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f0103010:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103013:	8d 83 81 61 f8 ff    	lea    -0x79e7f(%ebx),%eax
f0103019:	50                   	push   %eax
f010301a:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0103020:	50                   	push   %eax
f0103021:	68 f2 03 00 00       	push   $0x3f2
f0103026:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f010302c:	50                   	push   %eax
f010302d:	e8 7f d0 ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103032:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103035:	8d 83 a0 64 f8 ff    	lea    -0x79b60(%ebx),%eax
f010303b:	50                   	push   %eax
f010303c:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0103042:	50                   	push   %eax
f0103043:	68 f5 03 00 00       	push   $0x3f5
f0103048:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f010304e:	50                   	push   %eax
f010304f:	e8 5d d0 ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f0103054:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103057:	8d 83 38 61 f8 ff    	lea    -0x79ec8(%ebx),%eax
f010305d:	50                   	push   %eax
f010305e:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f0103064:	50                   	push   %eax
f0103065:	68 f7 03 00 00       	push   $0x3f7
f010306a:	8d 83 49 5f f8 ff    	lea    -0x7a0b7(%ebx),%eax
f0103070:	50                   	push   %eax
f0103071:	e8 3b d0 ff ff       	call   f01000b1 <_panic>

f0103076 <tlb_invalidate>:
{
f0103076:	55                   	push   %ebp
f0103077:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0103079:	8b 45 0c             	mov    0xc(%ebp),%eax
f010307c:	0f 01 38             	invlpg (%eax)
}
f010307f:	5d                   	pop    %ebp
f0103080:	c3                   	ret    

f0103081 <user_mem_check>:
{
f0103081:	55                   	push   %ebp
f0103082:	89 e5                	mov    %esp,%ebp
f0103084:	57                   	push   %edi
f0103085:	56                   	push   %esi
f0103086:	53                   	push   %ebx
f0103087:	83 ec 1c             	sub    $0x1c,%esp
f010308a:	e8 6a d6 ff ff       	call   f01006f9 <__x86.get_pc_thunk.ax>
f010308f:	05 9d c8 07 00       	add    $0x7c89d,%eax
f0103094:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103097:	8b 7d 08             	mov    0x8(%ebp),%edi
	uint32_t addr = (uint32_t)ROUNDDOWN(va, PGSIZE), end = (uint32_t)ROUNDUP(va+len, PGSIZE);
f010309a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010309d:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f01030a3:	8b 75 0c             	mov    0xc(%ebp),%esi
f01030a6:	03 75 10             	add    0x10(%ebp),%esi
f01030a9:	81 c6 ff 0f 00 00    	add    $0xfff,%esi
f01030af:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	while(addr < end)
f01030b5:	39 f3                	cmp    %esi,%ebx
f01030b7:	73 52                	jae    f010310b <user_mem_check+0x8a>
		pte_t *pte = pgdir_walk(env->env_pgdir, (void*)addr, 0);
f01030b9:	83 ec 04             	sub    $0x4,%esp
f01030bc:	6a 00                	push   $0x0
f01030be:	53                   	push   %ebx
f01030bf:	ff 77 5c             	push   0x5c(%edi)
f01030c2:	e8 9e df ff ff       	call   f0101065 <pgdir_walk>
		if ((addr>=ULIM) || !pte || !(*pte & PTE_P) || ((*pte & perm) != perm)) 
f01030c7:	83 c4 10             	add    $0x10,%esp
f01030ca:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01030d0:	77 1a                	ja     f01030ec <user_mem_check+0x6b>
f01030d2:	85 c0                	test   %eax,%eax
f01030d4:	74 16                	je     f01030ec <user_mem_check+0x6b>
f01030d6:	8b 00                	mov    (%eax),%eax
f01030d8:	a8 01                	test   $0x1,%al
f01030da:	74 10                	je     f01030ec <user_mem_check+0x6b>
f01030dc:	23 45 14             	and    0x14(%ebp),%eax
f01030df:	39 45 14             	cmp    %eax,0x14(%ebp)
f01030e2:	75 08                	jne    f01030ec <user_mem_check+0x6b>
		addr += PGSIZE;
f01030e4:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01030ea:	eb c9                	jmp    f01030b5 <user_mem_check+0x34>
			user_mem_check_addr = (addr<(uint32_t)va?(uint32_t)va:addr);
f01030ec:	39 5d 0c             	cmp    %ebx,0xc(%ebp)
f01030ef:	89 d8                	mov    %ebx,%eax
f01030f1:	0f 43 45 0c          	cmovae 0xc(%ebp),%eax
f01030f5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01030f8:	89 82 1c 1a 00 00    	mov    %eax,0x1a1c(%edx)
			return -E_FAULT;
f01030fe:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
}
f0103103:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103106:	5b                   	pop    %ebx
f0103107:	5e                   	pop    %esi
f0103108:	5f                   	pop    %edi
f0103109:	5d                   	pop    %ebp
f010310a:	c3                   	ret    
	return 0;
f010310b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103110:	eb f1                	jmp    f0103103 <user_mem_check+0x82>

f0103112 <user_mem_assert>:
{
f0103112:	55                   	push   %ebp
f0103113:	89 e5                	mov    %esp,%ebp
f0103115:	56                   	push   %esi
f0103116:	53                   	push   %ebx
f0103117:	e8 4b d0 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010311c:	81 c3 10 c8 07 00    	add    $0x7c810,%ebx
f0103122:	8b 75 08             	mov    0x8(%ebp),%esi
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0103125:	8b 45 14             	mov    0x14(%ebp),%eax
f0103128:	83 c8 04             	or     $0x4,%eax
f010312b:	50                   	push   %eax
f010312c:	ff 75 10             	push   0x10(%ebp)
f010312f:	ff 75 0c             	push   0xc(%ebp)
f0103132:	56                   	push   %esi
f0103133:	e8 49 ff ff ff       	call   f0103081 <user_mem_check>
f0103138:	83 c4 10             	add    $0x10,%esp
f010313b:	85 c0                	test   %eax,%eax
f010313d:	78 07                	js     f0103146 <user_mem_assert+0x34>
}
f010313f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103142:	5b                   	pop    %ebx
f0103143:	5e                   	pop    %esi
f0103144:	5d                   	pop    %ebp
f0103145:	c3                   	ret    
		cprintf("[%08x] user_mem_check assertion failure for "
f0103146:	83 ec 04             	sub    $0x4,%esp
f0103149:	ff b3 1c 1a 00 00    	push   0x1a1c(%ebx)
f010314f:	ff 76 48             	push   0x48(%esi)
f0103152:	8d 83 e8 69 f8 ff    	lea    -0x79618(%ebx),%eax
f0103158:	50                   	push   %eax
f0103159:	e8 b7 07 00 00       	call   f0103915 <cprintf>
		env_destroy(env);	// may not return
f010315e:	89 34 24             	mov    %esi,(%esp)
f0103161:	e8 56 06 00 00       	call   f01037bc <env_destroy>
f0103166:	83 c4 10             	add    $0x10,%esp
}
f0103169:	eb d4                	jmp    f010313f <user_mem_assert+0x2d>

f010316b <__x86.get_pc_thunk.dx>:
f010316b:	8b 14 24             	mov    (%esp),%edx
f010316e:	c3                   	ret    

f010316f <__x86.get_pc_thunk.cx>:
f010316f:	8b 0c 24             	mov    (%esp),%ecx
f0103172:	c3                   	ret    

f0103173 <__x86.get_pc_thunk.di>:
f0103173:	8b 3c 24             	mov    (%esp),%edi
f0103176:	c3                   	ret    

f0103177 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0103177:	55                   	push   %ebp
f0103178:	89 e5                	mov    %esp,%ebp
f010317a:	57                   	push   %edi
f010317b:	56                   	push   %esi
f010317c:	53                   	push   %ebx
f010317d:	83 ec 1c             	sub    $0x1c,%esp
f0103180:	e8 e2 cf ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103185:	81 c3 a7 c7 07 00    	add    $0x7c7a7,%ebx
f010318b:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void* addr = ROUNDDOWN(va, PGSIZE), *end = ROUNDUP(va+len, PGSIZE);
f010318d:	89 d6                	mov    %edx,%esi
f010318f:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
f0103195:	8d 84 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%eax
f010319c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01031a1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	while(addr < end)
f01031a4:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f01031a7:	73 43                	jae    f01031ec <region_alloc+0x75>
	{
		struct PageInfo *pg = page_alloc(0);
f01031a9:	83 ec 0c             	sub    $0xc,%esp
f01031ac:	6a 00                	push   $0x0
f01031ae:	e8 e4 dd ff ff       	call   f0100f97 <page_alloc>
		if (!pg) panic("region_alloc failed");
f01031b3:	83 c4 10             	add    $0x10,%esp
f01031b6:	85 c0                	test   %eax,%eax
f01031b8:	74 17                	je     f01031d1 <region_alloc+0x5a>
		page_insert(e->env_pgdir, pg, addr, PTE_W | PTE_U);
f01031ba:	6a 06                	push   $0x6
f01031bc:	56                   	push   %esi
f01031bd:	50                   	push   %eax
f01031be:	ff 77 5c             	push   0x5c(%edi)
f01031c1:	e8 a9 e0 ff ff       	call   f010126f <page_insert>
		addr += PGSIZE;
f01031c6:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01031cc:	83 c4 10             	add    $0x10,%esp
f01031cf:	eb d3                	jmp    f01031a4 <region_alloc+0x2d>
		if (!pg) panic("region_alloc failed");
f01031d1:	83 ec 04             	sub    $0x4,%esp
f01031d4:	8d 83 1d 6a f8 ff    	lea    -0x795e3(%ebx),%eax
f01031da:	50                   	push   %eax
f01031db:	68 1a 01 00 00       	push   $0x11a
f01031e0:	8d 83 31 6a f8 ff    	lea    -0x795cf(%ebx),%eax
f01031e6:	50                   	push   %eax
f01031e7:	e8 c5 ce ff ff       	call   f01000b1 <_panic>
	}
}
f01031ec:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01031ef:	5b                   	pop    %ebx
f01031f0:	5e                   	pop    %esi
f01031f1:	5f                   	pop    %edi
f01031f2:	5d                   	pop    %ebp
f01031f3:	c3                   	ret    

f01031f4 <envid2env>:
{
f01031f4:	55                   	push   %ebp
f01031f5:	89 e5                	mov    %esp,%ebp
f01031f7:	53                   	push   %ebx
f01031f8:	e8 72 ff ff ff       	call   f010316f <__x86.get_pc_thunk.cx>
f01031fd:	81 c1 2f c7 07 00    	add    $0x7c72f,%ecx
f0103203:	8b 45 08             	mov    0x8(%ebp),%eax
f0103206:	8b 5d 10             	mov    0x10(%ebp),%ebx
	if (envid == 0) {
f0103209:	85 c0                	test   %eax,%eax
f010320b:	74 4c                	je     f0103259 <envid2env+0x65>
	e = &envs[ENVX(envid)];
f010320d:	89 c2                	mov    %eax,%edx
f010320f:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0103215:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103218:	c1 e2 05             	shl    $0x5,%edx
f010321b:	03 91 28 1a 00 00    	add    0x1a28(%ecx),%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103221:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0103225:	74 42                	je     f0103269 <envid2env+0x75>
f0103227:	39 42 48             	cmp    %eax,0x48(%edx)
f010322a:	75 49                	jne    f0103275 <envid2env+0x81>
	return 0;
f010322c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103231:	84 db                	test   %bl,%bl
f0103233:	74 2a                	je     f010325f <envid2env+0x6b>
f0103235:	8b 89 24 1a 00 00    	mov    0x1a24(%ecx),%ecx
f010323b:	39 d1                	cmp    %edx,%ecx
f010323d:	74 20                	je     f010325f <envid2env+0x6b>
f010323f:	8b 42 4c             	mov    0x4c(%edx),%eax
f0103242:	3b 41 48             	cmp    0x48(%ecx),%eax
f0103245:	bb 00 00 00 00       	mov    $0x0,%ebx
f010324a:	0f 45 d3             	cmovne %ebx,%edx
f010324d:	0f 94 c0             	sete   %al
f0103250:	0f b6 c0             	movzbl %al,%eax
f0103253:	8d 44 00 fe          	lea    -0x2(%eax,%eax,1),%eax
f0103257:	eb 06                	jmp    f010325f <envid2env+0x6b>
		*env_store = curenv;
f0103259:	8b 91 24 1a 00 00    	mov    0x1a24(%ecx),%edx
f010325f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103262:	89 11                	mov    %edx,(%ecx)
}
f0103264:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103267:	c9                   	leave  
f0103268:	c3                   	ret    
f0103269:	ba 00 00 00 00       	mov    $0x0,%edx
		return -E_BAD_ENV;
f010326e:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103273:	eb ea                	jmp    f010325f <envid2env+0x6b>
f0103275:	ba 00 00 00 00       	mov    $0x0,%edx
f010327a:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010327f:	eb de                	jmp    f010325f <envid2env+0x6b>

f0103281 <env_init_percpu>:
{
f0103281:	e8 73 d4 ff ff       	call   f01006f9 <__x86.get_pc_thunk.ax>
f0103286:	05 a6 c6 07 00       	add    $0x7c6a6,%eax
	asm volatile("lgdt (%0)" : : "r" (p));
f010328b:	8d 80 d4 16 00 00    	lea    0x16d4(%eax),%eax
f0103291:	0f 01 10             	lgdtl  (%eax)
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0103294:	b8 23 00 00 00       	mov    $0x23,%eax
f0103299:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f010329b:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f010329d:	b8 10 00 00 00       	mov    $0x10,%eax
f01032a2:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f01032a4:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f01032a6:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f01032a8:	ea af 32 10 f0 08 00 	ljmp   $0x8,$0xf01032af
	asm volatile("lldt %0" : : "r" (sel));
f01032af:	b8 00 00 00 00       	mov    $0x0,%eax
f01032b4:	0f 00 d0             	lldt   %ax
}
f01032b7:	c3                   	ret    

f01032b8 <env_init>:
{
f01032b8:	55                   	push   %ebp
f01032b9:	89 e5                	mov    %esp,%ebp
f01032bb:	56                   	push   %esi
f01032bc:	53                   	push   %ebx
f01032bd:	e8 3b d4 ff ff       	call   f01006fd <__x86.get_pc_thunk.si>
f01032c2:	81 c6 6a c6 07 00    	add    $0x7c66a,%esi
		envs[i].env_id = 0;
f01032c8:	8b 9e 28 1a 00 00    	mov    0x1a28(%esi),%ebx
f01032ce:	8b 96 2c 1a 00 00    	mov    0x1a2c(%esi),%edx
f01032d4:	8d 83 a0 7f 01 00    	lea    0x17fa0(%ebx),%eax
f01032da:	89 d1                	mov    %edx,%ecx
f01032dc:	89 c2                	mov    %eax,%edx
f01032de:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f01032e5:	89 48 44             	mov    %ecx,0x44(%eax)
	for (int i = NENV-1;i >= 0; --i) 
f01032e8:	83 e8 60             	sub    $0x60,%eax
f01032eb:	39 da                	cmp    %ebx,%edx
f01032ed:	75 eb                	jne    f01032da <env_init+0x22>
f01032ef:	89 9e 2c 1a 00 00    	mov    %ebx,0x1a2c(%esi)
	env_init_percpu();
f01032f5:	e8 87 ff ff ff       	call   f0103281 <env_init_percpu>
}
f01032fa:	5b                   	pop    %ebx
f01032fb:	5e                   	pop    %esi
f01032fc:	5d                   	pop    %ebp
f01032fd:	c3                   	ret    

f01032fe <env_alloc>:
{
f01032fe:	55                   	push   %ebp
f01032ff:	89 e5                	mov    %esp,%ebp
f0103301:	56                   	push   %esi
f0103302:	53                   	push   %ebx
f0103303:	e8 5f ce ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103308:	81 c3 24 c6 07 00    	add    $0x7c624,%ebx
	if (!(e = env_free_list))
f010330e:	8b b3 2c 1a 00 00    	mov    0x1a2c(%ebx),%esi
f0103314:	85 f6                	test   %esi,%esi
f0103316:	0f 84 63 01 00 00    	je     f010347f <env_alloc+0x181>
	if (!(p = page_alloc(ALLOC_ZERO)))
f010331c:	83 ec 0c             	sub    $0xc,%esp
f010331f:	6a 01                	push   $0x1
f0103321:	e8 71 dc ff ff       	call   f0100f97 <page_alloc>
f0103326:	83 c4 10             	add    $0x10,%esp
f0103329:	85 c0                	test   %eax,%eax
f010332b:	0f 84 55 01 00 00    	je     f0103486 <env_alloc+0x188>
	p->pp_ref++;
f0103331:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0103336:	c7 c2 38 13 18 f0    	mov    $0xf0181338,%edx
f010333c:	2b 02                	sub    (%edx),%eax
f010333e:	c1 f8 03             	sar    $0x3,%eax
f0103341:	89 c2                	mov    %eax,%edx
f0103343:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0103346:	25 ff ff 0f 00       	and    $0xfffff,%eax
f010334b:	c7 c1 40 13 18 f0    	mov    $0xf0181340,%ecx
f0103351:	3b 01                	cmp    (%ecx),%eax
f0103353:	0f 83 f7 00 00 00    	jae    f0103450 <env_alloc+0x152>
	return (void *)(pa + KERNBASE);
f0103359:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	e->env_pgdir = (pde_t *) page2kva(p);
f010335f:	89 46 5c             	mov    %eax,0x5c(%esi)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0103362:	83 ec 04             	sub    $0x4,%esp
f0103365:	68 00 10 00 00       	push   $0x1000
f010336a:	c7 c2 3c 13 18 f0    	mov    $0xf018133c,%edx
f0103370:	ff 32                	push   (%edx)
f0103372:	50                   	push   %eax
f0103373:	e8 8c 1c 00 00       	call   f0105004 <memcpy>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103378:	8b 46 5c             	mov    0x5c(%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f010337b:	83 c4 10             	add    $0x10,%esp
f010337e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103383:	0f 86 dd 00 00 00    	jbe    f0103466 <env_alloc+0x168>
	return (physaddr_t)kva - KERNBASE;
f0103389:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010338f:	83 ca 05             	or     $0x5,%edx
f0103392:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0103398:	8b 46 48             	mov    0x48(%esi),%eax
f010339b:	05 00 10 00 00       	add    $0x1000,%eax
		generation = 1 << ENVGENSHIFT;
f01033a0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01033a5:	ba 00 10 00 00       	mov    $0x1000,%edx
f01033aa:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01033ad:	89 f2                	mov    %esi,%edx
f01033af:	2b 93 28 1a 00 00    	sub    0x1a28(%ebx),%edx
f01033b5:	c1 fa 05             	sar    $0x5,%edx
f01033b8:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01033be:	09 d0                	or     %edx,%eax
f01033c0:	89 46 48             	mov    %eax,0x48(%esi)
	e->env_parent_id = parent_id;
f01033c3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01033c6:	89 46 4c             	mov    %eax,0x4c(%esi)
	e->env_type = ENV_TYPE_USER;
f01033c9:	c7 46 50 00 00 00 00 	movl   $0x0,0x50(%esi)
	e->env_status = ENV_RUNNABLE;
f01033d0:	c7 46 54 02 00 00 00 	movl   $0x2,0x54(%esi)
	e->env_runs = 0;
f01033d7:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01033de:	83 ec 04             	sub    $0x4,%esp
f01033e1:	6a 44                	push   $0x44
f01033e3:	6a 00                	push   $0x0
f01033e5:	56                   	push   %esi
f01033e6:	e8 71 1b 00 00       	call   f0104f5c <memset>
	e->env_tf.tf_ds = GD_UD | 3;
f01033eb:	66 c7 46 24 23 00    	movw   $0x23,0x24(%esi)
	e->env_tf.tf_es = GD_UD | 3;
f01033f1:	66 c7 46 20 23 00    	movw   $0x23,0x20(%esi)
	e->env_tf.tf_ss = GD_UD | 3;
f01033f7:	66 c7 46 40 23 00    	movw   $0x23,0x40(%esi)
	e->env_tf.tf_esp = USTACKTOP;
f01033fd:	c7 46 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%esi)
	e->env_tf.tf_cs = GD_UT | 3;
f0103404:	66 c7 46 34 1b 00    	movw   $0x1b,0x34(%esi)
	env_free_list = e->env_link;
f010340a:	8b 46 44             	mov    0x44(%esi),%eax
f010340d:	89 83 2c 1a 00 00    	mov    %eax,0x1a2c(%ebx)
	*newenv_store = e;
f0103413:	8b 45 08             	mov    0x8(%ebp),%eax
f0103416:	89 30                	mov    %esi,(%eax)
	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103418:	8b 4e 48             	mov    0x48(%esi),%ecx
f010341b:	8b 83 24 1a 00 00    	mov    0x1a24(%ebx),%eax
f0103421:	83 c4 10             	add    $0x10,%esp
f0103424:	ba 00 00 00 00       	mov    $0x0,%edx
f0103429:	85 c0                	test   %eax,%eax
f010342b:	74 03                	je     f0103430 <env_alloc+0x132>
f010342d:	8b 50 48             	mov    0x48(%eax),%edx
f0103430:	83 ec 04             	sub    $0x4,%esp
f0103433:	51                   	push   %ecx
f0103434:	52                   	push   %edx
f0103435:	8d 83 3c 6a f8 ff    	lea    -0x795c4(%ebx),%eax
f010343b:	50                   	push   %eax
f010343c:	e8 d4 04 00 00       	call   f0103915 <cprintf>
	return 0;
f0103441:	83 c4 10             	add    $0x10,%esp
f0103444:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103449:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010344c:	5b                   	pop    %ebx
f010344d:	5e                   	pop    %esi
f010344e:	5d                   	pop    %ebp
f010344f:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103450:	52                   	push   %edx
f0103451:	8d 83 3c 62 f8 ff    	lea    -0x79dc4(%ebx),%eax
f0103457:	50                   	push   %eax
f0103458:	6a 56                	push   $0x56
f010345a:	8d 83 55 5f f8 ff    	lea    -0x7a0ab(%ebx),%eax
f0103460:	50                   	push   %eax
f0103461:	e8 4b cc ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103466:	50                   	push   %eax
f0103467:	8d 83 a4 63 f8 ff    	lea    -0x79c5c(%ebx),%eax
f010346d:	50                   	push   %eax
f010346e:	68 c1 00 00 00       	push   $0xc1
f0103473:	8d 83 31 6a f8 ff    	lea    -0x795cf(%ebx),%eax
f0103479:	50                   	push   %eax
f010347a:	e8 32 cc ff ff       	call   f01000b1 <_panic>
		return -E_NO_FREE_ENV;
f010347f:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103484:	eb c3                	jmp    f0103449 <env_alloc+0x14b>
		return -E_NO_MEM;
f0103486:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010348b:	eb bc                	jmp    f0103449 <env_alloc+0x14b>

f010348d <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010348d:	55                   	push   %ebp
f010348e:	89 e5                	mov    %esp,%ebp
f0103490:	57                   	push   %edi
f0103491:	56                   	push   %esi
f0103492:	53                   	push   %ebx
f0103493:	83 ec 34             	sub    $0x34,%esp
f0103496:	e8 cc cc ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010349b:	81 c3 91 c4 07 00    	add    $0x7c491,%ebx
	// LAB 3: Your code here.
	struct Env* p;
	env_alloc(&p, 0);
f01034a1:	6a 00                	push   $0x0
f01034a3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01034a6:	50                   	push   %eax
f01034a7:	e8 52 fe ff ff       	call   f01032fe <env_alloc>
	load_icode(p, binary);
f01034ac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
	if (ELFHDR->e_magic != ELF_MAGIC) panic("binary bad ELF");
f01034af:	83 c4 10             	add    $0x10,%esp
f01034b2:	8b 45 08             	mov    0x8(%ebp),%eax
f01034b5:	81 38 7f 45 4c 46    	cmpl   $0x464c457f,(%eax)
f01034bb:	75 28                	jne    f01034e5 <env_create+0x58>
	struct Proghdr* ph = (struct Proghdr*) ((uint8_t*) ELFHDR + ELFHDR->e_phoff);
f01034bd:	8b 45 08             	mov    0x8(%ebp),%eax
f01034c0:	89 c6                	mov    %eax,%esi
f01034c2:	03 70 1c             	add    0x1c(%eax),%esi
	struct Proghdr* eph = ph + ELFHDR->e_phnum;
f01034c5:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
f01034c9:	c1 e0 05             	shl    $0x5,%eax
f01034cc:	01 f0                	add    %esi,%eax
f01034ce:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	lcr3(PADDR(e->env_pgdir));
f01034d1:	8b 47 5c             	mov    0x5c(%edi),%eax
	if ((uint32_t)kva < KERNBASE)
f01034d4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034d9:	76 25                	jbe    f0103500 <env_create+0x73>
	return (physaddr_t)kva - KERNBASE;
f01034db:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01034e0:	0f 22 d8             	mov    %eax,%cr3
}
f01034e3:	eb 6c                	jmp    f0103551 <env_create+0xc4>
	if (ELFHDR->e_magic != ELF_MAGIC) panic("binary bad ELF");
f01034e5:	83 ec 04             	sub    $0x4,%esp
f01034e8:	8d 83 51 6a f8 ff    	lea    -0x795af(%ebx),%eax
f01034ee:	50                   	push   %eax
f01034ef:	68 58 01 00 00       	push   $0x158
f01034f4:	8d 83 31 6a f8 ff    	lea    -0x795cf(%ebx),%eax
f01034fa:	50                   	push   %eax
f01034fb:	e8 b1 cb ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103500:	50                   	push   %eax
f0103501:	8d 83 a4 63 f8 ff    	lea    -0x79c5c(%ebx),%eax
f0103507:	50                   	push   %eax
f0103508:	68 5c 01 00 00       	push   $0x15c
f010350d:	8d 83 31 6a f8 ff    	lea    -0x795cf(%ebx),%eax
f0103513:	50                   	push   %eax
f0103514:	e8 98 cb ff ff       	call   f01000b1 <_panic>
		region_alloc(e, (void*)ph->p_va, ph->p_memsz);
f0103519:	8b 4e 14             	mov    0x14(%esi),%ecx
f010351c:	8b 56 08             	mov    0x8(%esi),%edx
f010351f:	89 f8                	mov    %edi,%eax
f0103521:	e8 51 fc ff ff       	call   f0103177 <region_alloc>
		memset((void*)ph->p_va, 0, ph->p_memsz);
f0103526:	83 ec 04             	sub    $0x4,%esp
f0103529:	ff 76 14             	push   0x14(%esi)
f010352c:	6a 00                	push   $0x0
f010352e:	ff 76 08             	push   0x8(%esi)
f0103531:	e8 26 1a 00 00       	call   f0104f5c <memset>
		memcpy((void*)ph->p_va, binary+ph->p_offset, ph->p_filesz);
f0103536:	83 c4 0c             	add    $0xc,%esp
f0103539:	ff 76 10             	push   0x10(%esi)
f010353c:	8b 45 08             	mov    0x8(%ebp),%eax
f010353f:	03 46 04             	add    0x4(%esi),%eax
f0103542:	50                   	push   %eax
f0103543:	ff 76 08             	push   0x8(%esi)
f0103546:	e8 b9 1a 00 00       	call   f0105004 <memcpy>
		ph++;
f010354b:	83 c6 20             	add    $0x20,%esi
f010354e:	83 c4 10             	add    $0x10,%esp
	while(ph < eph)
f0103551:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0103554:	77 c3                	ja     f0103519 <env_create+0x8c>
	e->env_tf.tf_eip = ELFHDR->e_entry;
f0103556:	8b 45 08             	mov    0x8(%ebp),%eax
f0103559:	8b 40 18             	mov    0x18(%eax),%eax
f010355c:	89 47 30             	mov    %eax,0x30(%edi)
	lcr3(PADDR(kern_pgdir));
f010355f:	c7 c0 3c 13 18 f0    	mov    $0xf018133c,%eax
f0103565:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103567:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010356c:	76 21                	jbe    f010358f <env_create+0x102>
	return (physaddr_t)kva - KERNBASE;
f010356e:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103573:	0f 22 d8             	mov    %eax,%cr3
	region_alloc(e, (void*) (USTACKTOP - PGSIZE), PGSIZE);
f0103576:	b9 00 10 00 00       	mov    $0x1000,%ecx
f010357b:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103580:	89 f8                	mov    %edi,%eax
f0103582:	e8 f0 fb ff ff       	call   f0103177 <region_alloc>
}
f0103587:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010358a:	5b                   	pop    %ebx
f010358b:	5e                   	pop    %esi
f010358c:	5f                   	pop    %edi
f010358d:	5d                   	pop    %ebp
f010358e:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010358f:	50                   	push   %eax
f0103590:	8d 83 a4 63 f8 ff    	lea    -0x79c5c(%ebx),%eax
f0103596:	50                   	push   %eax
f0103597:	68 66 01 00 00       	push   $0x166
f010359c:	8d 83 31 6a f8 ff    	lea    -0x795cf(%ebx),%eax
f01035a2:	50                   	push   %eax
f01035a3:	e8 09 cb ff ff       	call   f01000b1 <_panic>

f01035a8 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01035a8:	55                   	push   %ebp
f01035a9:	89 e5                	mov    %esp,%ebp
f01035ab:	57                   	push   %edi
f01035ac:	56                   	push   %esi
f01035ad:	53                   	push   %ebx
f01035ae:	83 ec 2c             	sub    $0x2c,%esp
f01035b1:	e8 b1 cb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01035b6:	81 c3 76 c3 07 00    	add    $0x7c376,%ebx
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01035bc:	8b 93 24 1a 00 00    	mov    0x1a24(%ebx),%edx
f01035c2:	3b 55 08             	cmp    0x8(%ebp),%edx
f01035c5:	74 47                	je     f010360e <env_free+0x66>
		lcr3(PADDR(kern_pgdir));

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01035c7:	8b 45 08             	mov    0x8(%ebp),%eax
f01035ca:	8b 48 48             	mov    0x48(%eax),%ecx
f01035cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01035d2:	85 d2                	test   %edx,%edx
f01035d4:	74 03                	je     f01035d9 <env_free+0x31>
f01035d6:	8b 42 48             	mov    0x48(%edx),%eax
f01035d9:	83 ec 04             	sub    $0x4,%esp
f01035dc:	51                   	push   %ecx
f01035dd:	50                   	push   %eax
f01035de:	8d 83 60 6a f8 ff    	lea    -0x795a0(%ebx),%eax
f01035e4:	50                   	push   %eax
f01035e5:	e8 2b 03 00 00       	call   f0103915 <cprintf>
f01035ea:	83 c4 10             	add    $0x10,%esp
f01035ed:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	if (PGNUM(pa) >= npages)
f01035f4:	c7 c0 40 13 18 f0    	mov    $0xf0181340,%eax
f01035fa:	89 45 d8             	mov    %eax,-0x28(%ebp)
	if (PGNUM(pa) >= npages)
f01035fd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	return &pages[PGNUM(pa)];
f0103600:	c7 c0 38 13 18 f0    	mov    $0xf0181338,%eax
f0103606:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103609:	e9 bf 00 00 00       	jmp    f01036cd <env_free+0x125>
		lcr3(PADDR(kern_pgdir));
f010360e:	c7 c0 3c 13 18 f0    	mov    $0xf018133c,%eax
f0103614:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103616:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010361b:	76 10                	jbe    f010362d <env_free+0x85>
	return (physaddr_t)kva - KERNBASE;
f010361d:	05 00 00 00 10       	add    $0x10000000,%eax
f0103622:	0f 22 d8             	mov    %eax,%cr3
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103625:	8b 45 08             	mov    0x8(%ebp),%eax
f0103628:	8b 48 48             	mov    0x48(%eax),%ecx
f010362b:	eb a9                	jmp    f01035d6 <env_free+0x2e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010362d:	50                   	push   %eax
f010362e:	8d 83 a4 63 f8 ff    	lea    -0x79c5c(%ebx),%eax
f0103634:	50                   	push   %eax
f0103635:	68 8c 01 00 00       	push   $0x18c
f010363a:	8d 83 31 6a f8 ff    	lea    -0x795cf(%ebx),%eax
f0103640:	50                   	push   %eax
f0103641:	e8 6b ca ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103646:	57                   	push   %edi
f0103647:	8d 83 3c 62 f8 ff    	lea    -0x79dc4(%ebx),%eax
f010364d:	50                   	push   %eax
f010364e:	68 9b 01 00 00       	push   $0x19b
f0103653:	8d 83 31 6a f8 ff    	lea    -0x795cf(%ebx),%eax
f0103659:	50                   	push   %eax
f010365a:	e8 52 ca ff ff       	call   f01000b1 <_panic>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010365f:	83 c7 04             	add    $0x4,%edi
f0103662:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0103668:	81 fe 00 00 40 00    	cmp    $0x400000,%esi
f010366e:	74 1e                	je     f010368e <env_free+0xe6>
			if (pt[pteno] & PTE_P)
f0103670:	f6 07 01             	testb  $0x1,(%edi)
f0103673:	74 ea                	je     f010365f <env_free+0xb7>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103675:	83 ec 08             	sub    $0x8,%esp
f0103678:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010367b:	09 f0                	or     %esi,%eax
f010367d:	50                   	push   %eax
f010367e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103681:	ff 70 5c             	push   0x5c(%eax)
f0103684:	e8 ab db ff ff       	call   f0101234 <page_remove>
f0103689:	83 c4 10             	add    $0x10,%esp
f010368c:	eb d1                	jmp    f010365f <env_free+0xb7>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f010368e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103691:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103694:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103697:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f010369e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01036a1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01036a4:	3b 10                	cmp    (%eax),%edx
f01036a6:	73 67                	jae    f010370f <env_free+0x167>
		page_decref(pa2page(pa));
f01036a8:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01036ab:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01036ae:	8b 00                	mov    (%eax),%eax
f01036b0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01036b3:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01036b6:	50                   	push   %eax
f01036b7:	e8 80 d9 ff ff       	call   f010103c <page_decref>
f01036bc:	83 c4 10             	add    $0x10,%esp
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01036bf:	83 45 e0 04          	addl   $0x4,-0x20(%ebp)
f01036c3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01036c6:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f01036cb:	74 5a                	je     f0103727 <env_free+0x17f>
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01036cd:	8b 45 08             	mov    0x8(%ebp),%eax
f01036d0:	8b 40 5c             	mov    0x5c(%eax),%eax
f01036d3:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01036d6:	8b 04 08             	mov    (%eax,%ecx,1),%eax
f01036d9:	a8 01                	test   $0x1,%al
f01036db:	74 e2                	je     f01036bf <env_free+0x117>
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01036dd:	89 c7                	mov    %eax,%edi
f01036df:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	if (PGNUM(pa) >= npages)
f01036e5:	c1 e8 0c             	shr    $0xc,%eax
f01036e8:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01036eb:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01036ee:	3b 02                	cmp    (%edx),%eax
f01036f0:	0f 83 50 ff ff ff    	jae    f0103646 <env_free+0x9e>
	return (void *)(pa + KERNBASE);
f01036f6:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
f01036fc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01036ff:	c1 e0 14             	shl    $0x14,%eax
f0103702:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103705:	be 00 00 00 00       	mov    $0x0,%esi
f010370a:	e9 61 ff ff ff       	jmp    f0103670 <env_free+0xc8>
		panic("pa2page called with invalid pa");
f010370f:	83 ec 04             	sub    $0x4,%esp
f0103712:	8d 83 48 63 f8 ff    	lea    -0x79cb8(%ebx),%eax
f0103718:	50                   	push   %eax
f0103719:	6a 4f                	push   $0x4f
f010371b:	8d 83 55 5f f8 ff    	lea    -0x7a0ab(%ebx),%eax
f0103721:	50                   	push   %eax
f0103722:	e8 8a c9 ff ff       	call   f01000b1 <_panic>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103727:	8b 45 08             	mov    0x8(%ebp),%eax
f010372a:	8b 40 5c             	mov    0x5c(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010372d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103732:	76 57                	jbe    f010378b <env_free+0x1e3>
	e->env_pgdir = 0;
f0103734:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103737:	c7 41 5c 00 00 00 00 	movl   $0x0,0x5c(%ecx)
	return (physaddr_t)kva - KERNBASE;
f010373e:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f0103743:	c1 e8 0c             	shr    $0xc,%eax
f0103746:	c7 c2 40 13 18 f0    	mov    $0xf0181340,%edx
f010374c:	3b 02                	cmp    (%edx),%eax
f010374e:	73 54                	jae    f01037a4 <env_free+0x1fc>
	page_decref(pa2page(pa));
f0103750:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103753:	c7 c2 38 13 18 f0    	mov    $0xf0181338,%edx
f0103759:	8b 12                	mov    (%edx),%edx
f010375b:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010375e:	50                   	push   %eax
f010375f:	e8 d8 d8 ff ff       	call   f010103c <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103764:	8b 45 08             	mov    0x8(%ebp),%eax
f0103767:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	e->env_link = env_free_list;
f010376e:	8b 83 2c 1a 00 00    	mov    0x1a2c(%ebx),%eax
f0103774:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103777:	89 41 44             	mov    %eax,0x44(%ecx)
	env_free_list = e;
f010377a:	89 8b 2c 1a 00 00    	mov    %ecx,0x1a2c(%ebx)
}
f0103780:	83 c4 10             	add    $0x10,%esp
f0103783:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103786:	5b                   	pop    %ebx
f0103787:	5e                   	pop    %esi
f0103788:	5f                   	pop    %edi
f0103789:	5d                   	pop    %ebp
f010378a:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010378b:	50                   	push   %eax
f010378c:	8d 83 a4 63 f8 ff    	lea    -0x79c5c(%ebx),%eax
f0103792:	50                   	push   %eax
f0103793:	68 a9 01 00 00       	push   $0x1a9
f0103798:	8d 83 31 6a f8 ff    	lea    -0x795cf(%ebx),%eax
f010379e:	50                   	push   %eax
f010379f:	e8 0d c9 ff ff       	call   f01000b1 <_panic>
		panic("pa2page called with invalid pa");
f01037a4:	83 ec 04             	sub    $0x4,%esp
f01037a7:	8d 83 48 63 f8 ff    	lea    -0x79cb8(%ebx),%eax
f01037ad:	50                   	push   %eax
f01037ae:	6a 4f                	push   $0x4f
f01037b0:	8d 83 55 5f f8 ff    	lea    -0x7a0ab(%ebx),%eax
f01037b6:	50                   	push   %eax
f01037b7:	e8 f5 c8 ff ff       	call   f01000b1 <_panic>

f01037bc <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f01037bc:	55                   	push   %ebp
f01037bd:	89 e5                	mov    %esp,%ebp
f01037bf:	53                   	push   %ebx
f01037c0:	83 ec 10             	sub    $0x10,%esp
f01037c3:	e8 9f c9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01037c8:	81 c3 64 c1 07 00    	add    $0x7c164,%ebx
	env_free(e);
f01037ce:	ff 75 08             	push   0x8(%ebp)
f01037d1:	e8 d2 fd ff ff       	call   f01035a8 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f01037d6:	8d 83 84 6a f8 ff    	lea    -0x7957c(%ebx),%eax
f01037dc:	89 04 24             	mov    %eax,(%esp)
f01037df:	e8 31 01 00 00       	call   f0103915 <cprintf>
f01037e4:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f01037e7:	83 ec 0c             	sub    $0xc,%esp
f01037ea:	6a 00                	push   $0x0
f01037ec:	e8 c2 d0 ff ff       	call   f01008b3 <monitor>
f01037f1:	83 c4 10             	add    $0x10,%esp
f01037f4:	eb f1                	jmp    f01037e7 <env_destroy+0x2b>

f01037f6 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01037f6:	55                   	push   %ebp
f01037f7:	89 e5                	mov    %esp,%ebp
f01037f9:	53                   	push   %ebx
f01037fa:	83 ec 08             	sub    $0x8,%esp
f01037fd:	e8 65 c9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103802:	81 c3 2a c1 07 00    	add    $0x7c12a,%ebx
	asm volatile(
f0103808:	8b 65 08             	mov    0x8(%ebp),%esp
f010380b:	61                   	popa   
f010380c:	07                   	pop    %es
f010380d:	1f                   	pop    %ds
f010380e:	83 c4 08             	add    $0x8,%esp
f0103811:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103812:	8d 83 76 6a f8 ff    	lea    -0x7958a(%ebx),%eax
f0103818:	50                   	push   %eax
f0103819:	68 d2 01 00 00       	push   $0x1d2
f010381e:	8d 83 31 6a f8 ff    	lea    -0x795cf(%ebx),%eax
f0103824:	50                   	push   %eax
f0103825:	e8 87 c8 ff ff       	call   f01000b1 <_panic>

f010382a <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010382a:	55                   	push   %ebp
f010382b:	89 e5                	mov    %esp,%ebp
f010382d:	53                   	push   %ebx
f010382e:	83 ec 04             	sub    $0x4,%esp
f0103831:	e8 31 c9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103836:	81 c3 f6 c0 07 00    	add    $0x7c0f6,%ebx
f010383c:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if (curenv != e) 
f010383f:	39 83 24 1a 00 00    	cmp    %eax,0x1a24(%ebx)
f0103845:	74 25                	je     f010386c <env_run+0x42>
	{
		curenv = e;
f0103847:	89 83 24 1a 00 00    	mov    %eax,0x1a24(%ebx)
		e->env_status = ENV_RUNNING;
f010384d:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
		e->env_runs++;
f0103854:	83 40 58 01          	addl   $0x1,0x58(%eax)
		lcr3(PADDR(e->env_pgdir));
f0103858:	8b 50 5c             	mov    0x5c(%eax),%edx
	if ((uint32_t)kva < KERNBASE)
f010385b:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103861:	76 12                	jbe    f0103875 <env_run+0x4b>
	return (physaddr_t)kva - KERNBASE;
f0103863:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0103869:	0f 22 da             	mov    %edx,%cr3
	}
	env_pop_tf(&e->env_tf);
f010386c:	83 ec 0c             	sub    $0xc,%esp
f010386f:	50                   	push   %eax
f0103870:	e8 81 ff ff ff       	call   f01037f6 <env_pop_tf>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103875:	52                   	push   %edx
f0103876:	8d 83 a4 63 f8 ff    	lea    -0x79c5c(%ebx),%eax
f010387c:	50                   	push   %eax
f010387d:	68 f5 01 00 00       	push   $0x1f5
f0103882:	8d 83 31 6a f8 ff    	lea    -0x795cf(%ebx),%eax
f0103888:	50                   	push   %eax
f0103889:	e8 23 c8 ff ff       	call   f01000b1 <_panic>

f010388e <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010388e:	55                   	push   %ebp
f010388f:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103891:	8b 45 08             	mov    0x8(%ebp),%eax
f0103894:	ba 70 00 00 00       	mov    $0x70,%edx
f0103899:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010389a:	ba 71 00 00 00       	mov    $0x71,%edx
f010389f:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01038a0:	0f b6 c0             	movzbl %al,%eax
}
f01038a3:	5d                   	pop    %ebp
f01038a4:	c3                   	ret    

f01038a5 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01038a5:	55                   	push   %ebp
f01038a6:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01038a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01038ab:	ba 70 00 00 00       	mov    $0x70,%edx
f01038b0:	ee                   	out    %al,(%dx)
f01038b1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038b4:	ba 71 00 00 00       	mov    $0x71,%edx
f01038b9:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01038ba:	5d                   	pop    %ebp
f01038bb:	c3                   	ret    

f01038bc <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01038bc:	55                   	push   %ebp
f01038bd:	89 e5                	mov    %esp,%ebp
f01038bf:	53                   	push   %ebx
f01038c0:	83 ec 10             	sub    $0x10,%esp
f01038c3:	e8 9f c8 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01038c8:	81 c3 64 c0 07 00    	add    $0x7c064,%ebx
	cputchar(ch);
f01038ce:	ff 75 08             	push   0x8(%ebp)
f01038d1:	e8 fc cd ff ff       	call   f01006d2 <cputchar>
	*cnt++;
}
f01038d6:	83 c4 10             	add    $0x10,%esp
f01038d9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01038dc:	c9                   	leave  
f01038dd:	c3                   	ret    

f01038de <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01038de:	55                   	push   %ebp
f01038df:	89 e5                	mov    %esp,%ebp
f01038e1:	53                   	push   %ebx
f01038e2:	83 ec 14             	sub    $0x14,%esp
f01038e5:	e8 7d c8 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01038ea:	81 c3 42 c0 07 00    	add    $0x7c042,%ebx
	int cnt = 0;
f01038f0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01038f7:	ff 75 0c             	push   0xc(%ebp)
f01038fa:	ff 75 08             	push   0x8(%ebp)
f01038fd:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103900:	50                   	push   %eax
f0103901:	8d 83 90 3f f8 ff    	lea    -0x7c070(%ebx),%eax
f0103907:	50                   	push   %eax
f0103908:	e8 da 0e 00 00       	call   f01047e7 <vprintfmt>
	return cnt;
}
f010390d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103910:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103913:	c9                   	leave  
f0103914:	c3                   	ret    

f0103915 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103915:	55                   	push   %ebp
f0103916:	89 e5                	mov    %esp,%ebp
f0103918:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010391b:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010391e:	50                   	push   %eax
f010391f:	ff 75 08             	push   0x8(%ebp)
f0103922:	e8 b7 ff ff ff       	call   f01038de <vcprintf>
	va_end(ap);

	return cnt;
}
f0103927:	c9                   	leave  
f0103928:	c3                   	ret    

f0103929 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103929:	55                   	push   %ebp
f010392a:	89 e5                	mov    %esp,%ebp
f010392c:	57                   	push   %edi
f010392d:	56                   	push   %esi
f010392e:	53                   	push   %ebx
f010392f:	83 ec 04             	sub    $0x4,%esp
f0103932:	e8 30 c8 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103937:	81 c3 f5 bf 07 00    	add    $0x7bff5,%ebx
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f010393d:	c7 83 58 22 00 00 00 	movl   $0xf0000000,0x2258(%ebx)
f0103944:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0103947:	66 c7 83 5c 22 00 00 	movw   $0x10,0x225c(%ebx)
f010394e:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f0103950:	66 c7 83 ba 22 00 00 	movw   $0x68,0x22ba(%ebx)
f0103957:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103959:	c7 c0 00 c3 11 f0    	mov    $0xf011c300,%eax
f010395f:	66 c7 40 28 67 00    	movw   $0x67,0x28(%eax)
f0103965:	8d b3 54 22 00 00    	lea    0x2254(%ebx),%esi
f010396b:	66 89 70 2a          	mov    %si,0x2a(%eax)
f010396f:	89 f2                	mov    %esi,%edx
f0103971:	c1 ea 10             	shr    $0x10,%edx
f0103974:	88 50 2c             	mov    %dl,0x2c(%eax)
f0103977:	0f b6 50 2d          	movzbl 0x2d(%eax),%edx
f010397b:	83 e2 f0             	and    $0xfffffff0,%edx
f010397e:	83 ca 09             	or     $0x9,%edx
f0103981:	83 e2 9f             	and    $0xffffff9f,%edx
f0103984:	83 ca 80             	or     $0xffffff80,%edx
f0103987:	88 55 f3             	mov    %dl,-0xd(%ebp)
f010398a:	88 50 2d             	mov    %dl,0x2d(%eax)
f010398d:	0f b6 48 2e          	movzbl 0x2e(%eax),%ecx
f0103991:	83 e1 c0             	and    $0xffffffc0,%ecx
f0103994:	83 c9 40             	or     $0x40,%ecx
f0103997:	83 e1 7f             	and    $0x7f,%ecx
f010399a:	88 48 2e             	mov    %cl,0x2e(%eax)
f010399d:	c1 ee 18             	shr    $0x18,%esi
f01039a0:	89 f1                	mov    %esi,%ecx
f01039a2:	88 48 2f             	mov    %cl,0x2f(%eax)
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f01039a5:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
f01039a9:	83 e2 ef             	and    $0xffffffef,%edx
f01039ac:	88 50 2d             	mov    %dl,0x2d(%eax)
	asm volatile("ltr %0" : : "r" (sel));
f01039af:	b8 28 00 00 00       	mov    $0x28,%eax
f01039b4:	0f 00 d8             	ltr    %ax
	asm volatile("lidt (%0)" : : "r" (p));
f01039b7:	8d 83 dc 16 00 00    	lea    0x16dc(%ebx),%eax
f01039bd:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f01039c0:	83 c4 04             	add    $0x4,%esp
f01039c3:	5b                   	pop    %ebx
f01039c4:	5e                   	pop    %esi
f01039c5:	5f                   	pop    %edi
f01039c6:	5d                   	pop    %ebp
f01039c7:	c3                   	ret    

f01039c8 <trap_init>:
{
f01039c8:	55                   	push   %ebp
f01039c9:	89 e5                	mov    %esp,%ebp
f01039cb:	57                   	push   %edi
f01039cc:	56                   	push   %esi
f01039cd:	53                   	push   %ebx
f01039ce:	83 ec 1c             	sub    $0x1c,%esp
f01039d1:	e8 91 c7 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01039d6:	81 c3 56 bf 07 00    	add    $0x7bf56,%ebx
	for (int i = 0; i < 17; ++i)
f01039dc:	ba 00 00 00 00       	mov    $0x0,%edx
		else if (i!=2 && i!=15) SETGATE(idt[i], 0, GD_KT, vectors[i], 0);
f01039e1:	c7 c0 30 c3 11 f0    	mov    $0xf011c330,%eax
f01039e7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01039ea:	8d 05 34 1a 00 00    	lea    0x1a34,%eax
f01039f0:	89 45 e8             	mov    %eax,-0x18(%ebp)
	for (int i = 0; i < 17; ++i)
f01039f3:	b8 00 00 00 00       	mov    $0x0,%eax
		if (i==T_BRKPT) SETGATE(idt[i], 0, GD_KT, vectors[i], 3)
f01039f8:	c7 c7 30 c3 11 f0    	mov    $0xf011c330,%edi
		else if (i!=2 && i!=15) SETGATE(idt[i], 0, GD_KT, vectors[i], 0);
f01039fe:	83 fa 02             	cmp    $0x2,%edx
f0103a01:	74 36                	je     f0103a39 <trap_init+0x71>
f0103a03:	83 fa 0f             	cmp    $0xf,%edx
f0103a06:	74 31                	je     f0103a39 <trap_init+0x71>
f0103a08:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103a0b:	8b 34 91             	mov    (%ecx,%edx,4),%esi
f0103a0e:	66 89 b4 d3 34 1a 00 	mov    %si,0x1a34(%ebx,%edx,8)
f0103a15:	00 
f0103a16:	8d 0c d3             	lea    (%ebx,%edx,8),%ecx
f0103a19:	03 4d e8             	add    -0x18(%ebp),%ecx
f0103a1c:	66 c7 41 02 08 00    	movw   $0x8,0x2(%ecx)
f0103a22:	c6 84 d3 38 1a 00 00 	movb   $0x0,0x1a38(%ebx,%edx,8)
f0103a29:	00 
f0103a2a:	c6 84 d3 39 1a 00 00 	movb   $0x8e,0x1a39(%ebx,%edx,8)
f0103a31:	8e 
f0103a32:	c1 ee 10             	shr    $0x10,%esi
f0103a35:	66 89 71 06          	mov    %si,0x6(%ecx)
	for (int i = 0; i < 17; ++i)
f0103a39:	89 c6                	mov    %eax,%esi
f0103a3b:	88 45 f3             	mov    %al,-0xd(%ebp)
f0103a3e:	88 45 f2             	mov    %al,-0xe(%ebp)
f0103a41:	88 45 f1             	mov    %al,-0xf(%ebp)
f0103a44:	88 45 f0             	mov    %al,-0x10(%ebp)
f0103a47:	88 45 ec             	mov    %al,-0x14(%ebp)
f0103a4a:	88 45 ed             	mov    %al,-0x13(%ebp)
f0103a4d:	88 45 ee             	mov    %al,-0x12(%ebp)
f0103a50:	88 45 ef             	mov    %al,-0x11(%ebp)
f0103a53:	b9 01 00 00 00       	mov    $0x1,%ecx
f0103a58:	83 c2 01             	add    $0x1,%edx
f0103a5b:	83 fa 10             	cmp    $0x10,%edx
f0103a5e:	0f 8f 8a 01 00 00    	jg     f0103bee <trap_init+0x226>
		if (i==T_BRKPT) SETGATE(idt[i], 0, GD_KT, vectors[i], 3)
f0103a64:	83 fa 03             	cmp    $0x3,%edx
f0103a67:	74 6b                	je     f0103ad4 <trap_init+0x10c>
f0103a69:	89 f1                	mov    %esi,%ecx
f0103a6b:	84 c9                	test   %cl,%cl
f0103a6d:	0f 85 99 00 00 00    	jne    f0103b0c <trap_init+0x144>
f0103a73:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
f0103a77:	0f 85 a0 00 00 00    	jne    f0103b1d <trap_init+0x155>
f0103a7d:	80 7d f2 00          	cmpb   $0x0,-0xe(%ebp)
f0103a81:	0f 85 b4 00 00 00    	jne    f0103b3b <trap_init+0x173>
f0103a87:	80 7d f1 00          	cmpb   $0x0,-0xf(%ebp)
f0103a8b:	0f 85 ce 00 00 00    	jne    f0103b5f <trap_init+0x197>
f0103a91:	80 7d f0 00          	cmpb   $0x0,-0x10(%ebp)
f0103a95:	0f 85 e7 00 00 00    	jne    f0103b82 <trap_init+0x1ba>
f0103a9b:	80 7d ec 00          	cmpb   $0x0,-0x14(%ebp)
f0103a9f:	0f 85 fe 00 00 00    	jne    f0103ba3 <trap_init+0x1db>
f0103aa5:	80 7d ed 00          	cmpb   $0x0,-0x13(%ebp)
f0103aa9:	0f 85 12 01 00 00    	jne    f0103bc1 <trap_init+0x1f9>
f0103aaf:	80 7d ee 00          	cmpb   $0x0,-0x12(%ebp)
f0103ab3:	0f 85 26 01 00 00    	jne    f0103bdf <trap_init+0x217>
f0103ab9:	80 7d ef 00          	cmpb   $0x0,-0x11(%ebp)
f0103abd:	0f 84 3b ff ff ff    	je     f01039fe <trap_init+0x36>
f0103ac3:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0103ac6:	0f b7 75 dc          	movzwl -0x24(%ebp),%esi
f0103aca:	66 89 74 0b 18       	mov    %si,0x18(%ebx,%ecx,1)
f0103acf:	e9 2a ff ff ff       	jmp    f01039fe <trap_init+0x36>
f0103ad4:	8b 77 0c             	mov    0xc(%edi),%esi
f0103ad7:	66 89 75 dc          	mov    %si,-0x24(%ebp)
f0103adb:	c1 ee 10             	shr    $0x10,%esi
f0103ade:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0103ae1:	89 ce                	mov    %ecx,%esi
f0103ae3:	88 4d f3             	mov    %cl,-0xd(%ebp)
f0103ae6:	88 4d df             	mov    %cl,-0x21(%ebp)
f0103ae9:	88 4d f2             	mov    %cl,-0xe(%ebp)
f0103aec:	88 4d f1             	mov    %cl,-0xf(%ebp)
f0103aef:	88 45 de             	mov    %al,-0x22(%ebp)
f0103af2:	88 4d f0             	mov    %cl,-0x10(%ebp)
f0103af5:	88 4d ec             	mov    %cl,-0x14(%ebp)
f0103af8:	88 45 da             	mov    %al,-0x26(%ebp)
f0103afb:	88 4d ed             	mov    %cl,-0x13(%ebp)
f0103afe:	88 45 db             	mov    %al,-0x25(%ebp)
f0103b01:	88 4d ee             	mov    %cl,-0x12(%ebp)
f0103b04:	88 4d ef             	mov    %cl,-0x11(%ebp)
f0103b07:	e9 4c ff ff ff       	jmp    f0103a58 <trap_init+0x90>
f0103b0c:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0103b0f:	0f b7 75 e4          	movzwl -0x1c(%ebp),%esi
f0103b13:	66 89 74 0b 1e       	mov    %si,0x1e(%ebx,%ecx,1)
f0103b18:	e9 56 ff ff ff       	jmp    f0103a73 <trap_init+0xab>
f0103b1d:	0f b6 75 df          	movzbl -0x21(%ebp),%esi
f0103b21:	c1 e6 07             	shl    $0x7,%esi
f0103b24:	0f b6 8b 51 1a 00 00 	movzbl 0x1a51(%ebx),%ecx
f0103b2b:	83 e1 7f             	and    $0x7f,%ecx
f0103b2e:	09 f1                	or     %esi,%ecx
f0103b30:	88 8b 51 1a 00 00    	mov    %cl,0x1a51(%ebx)
f0103b36:	e9 42 ff ff ff       	jmp    f0103a7d <trap_init+0xb5>
f0103b3b:	b9 03 00 00 00       	mov    $0x3,%ecx
f0103b40:	83 e1 03             	and    $0x3,%ecx
f0103b43:	89 ce                	mov    %ecx,%esi
f0103b45:	c1 e6 05             	shl    $0x5,%esi
f0103b48:	0f b6 8b 51 1a 00 00 	movzbl 0x1a51(%ebx),%ecx
f0103b4f:	83 e1 9f             	and    $0xffffff9f,%ecx
f0103b52:	09 f1                	or     %esi,%ecx
f0103b54:	88 8b 51 1a 00 00    	mov    %cl,0x1a51(%ebx)
f0103b5a:	e9 28 ff ff ff       	jmp    f0103a87 <trap_init+0xbf>
f0103b5f:	0f b6 4d de          	movzbl -0x22(%ebp),%ecx
f0103b63:	83 e1 01             	and    $0x1,%ecx
f0103b66:	c1 e1 04             	shl    $0x4,%ecx
f0103b69:	89 ce                	mov    %ecx,%esi
f0103b6b:	0f b6 8b 51 1a 00 00 	movzbl 0x1a51(%ebx),%ecx
f0103b72:	83 e1 ef             	and    $0xffffffef,%ecx
f0103b75:	09 f1                	or     %esi,%ecx
f0103b77:	88 8b 51 1a 00 00    	mov    %cl,0x1a51(%ebx)
f0103b7d:	e9 0f ff ff ff       	jmp    f0103a91 <trap_init+0xc9>
f0103b82:	b9 0e 00 00 00       	mov    $0xe,%ecx
f0103b87:	83 e1 0f             	and    $0xf,%ecx
f0103b8a:	89 ce                	mov    %ecx,%esi
f0103b8c:	0f b6 8b 51 1a 00 00 	movzbl 0x1a51(%ebx),%ecx
f0103b93:	83 e1 f0             	and    $0xfffffff0,%ecx
f0103b96:	09 f1                	or     %esi,%ecx
f0103b98:	88 8b 51 1a 00 00    	mov    %cl,0x1a51(%ebx)
f0103b9e:	e9 f8 fe ff ff       	jmp    f0103a9b <trap_init+0xd3>
f0103ba3:	0f b6 75 da          	movzbl -0x26(%ebp),%esi
f0103ba7:	c1 e6 05             	shl    $0x5,%esi
f0103baa:	0f b6 8b 50 1a 00 00 	movzbl 0x1a50(%ebx),%ecx
f0103bb1:	83 e1 1f             	and    $0x1f,%ecx
f0103bb4:	09 f1                	or     %esi,%ecx
f0103bb6:	88 8b 50 1a 00 00    	mov    %cl,0x1a50(%ebx)
f0103bbc:	e9 e4 fe ff ff       	jmp    f0103aa5 <trap_init+0xdd>
f0103bc1:	0f b6 75 db          	movzbl -0x25(%ebp),%esi
f0103bc5:	83 e6 1f             	and    $0x1f,%esi
f0103bc8:	0f b6 8b 50 1a 00 00 	movzbl 0x1a50(%ebx),%ecx
f0103bcf:	83 e1 e0             	and    $0xffffffe0,%ecx
f0103bd2:	09 f1                	or     %esi,%ecx
f0103bd4:	88 8b 50 1a 00 00    	mov    %cl,0x1a50(%ebx)
f0103bda:	e9 d0 fe ff ff       	jmp    f0103aaf <trap_init+0xe7>
f0103bdf:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0103be2:	66 c7 44 0b 1a 08 00 	movw   $0x8,0x1a(%ebx,%ecx,1)
f0103be9:	e9 cb fe ff ff       	jmp    f0103ab9 <trap_init+0xf1>
f0103bee:	89 f0                	mov    %esi,%eax
f0103bf0:	84 c0                	test   %al,%al
f0103bf2:	0f 85 91 00 00 00    	jne    f0103c89 <trap_init+0x2c1>
f0103bf8:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
f0103bfc:	0f 85 97 00 00 00    	jne    f0103c99 <trap_init+0x2d1>
f0103c02:	80 7d f2 00          	cmpb   $0x0,-0xe(%ebp)
f0103c06:	0f 85 ab 00 00 00    	jne    f0103cb7 <trap_init+0x2ef>
f0103c0c:	80 7d f1 00          	cmpb   $0x0,-0xf(%ebp)
f0103c10:	0f 85 c5 00 00 00    	jne    f0103cdb <trap_init+0x313>
f0103c16:	80 7d f0 00          	cmpb   $0x0,-0x10(%ebp)
f0103c1a:	0f 85 de 00 00 00    	jne    f0103cfe <trap_init+0x336>
f0103c20:	80 7d ec 00          	cmpb   $0x0,-0x14(%ebp)
f0103c24:	0f 85 f3 00 00 00    	jne    f0103d1d <trap_init+0x355>
f0103c2a:	80 7d ed 00          	cmpb   $0x0,-0x13(%ebp)
f0103c2e:	0f 85 07 01 00 00    	jne    f0103d3b <trap_init+0x373>
f0103c34:	80 7d ee 00          	cmpb   $0x0,-0x12(%ebp)
f0103c38:	0f 85 1b 01 00 00    	jne    f0103d59 <trap_init+0x391>
f0103c3e:	80 7d ef 00          	cmpb   $0x0,-0x11(%ebp)
f0103c42:	0f 85 1f 01 00 00    	jne    f0103d67 <trap_init+0x39f>
	SETGATE(idt[48], 0, GD_KT, vectors[48], 3);
f0103c48:	c7 c0 30 c3 11 f0    	mov    $0xf011c330,%eax
f0103c4e:	8b 80 c0 00 00 00    	mov    0xc0(%eax),%eax
f0103c54:	66 89 83 b4 1b 00 00 	mov    %ax,0x1bb4(%ebx)
f0103c5b:	66 c7 83 b6 1b 00 00 	movw   $0x8,0x1bb6(%ebx)
f0103c62:	08 00 
f0103c64:	c6 83 b8 1b 00 00 00 	movb   $0x0,0x1bb8(%ebx)
f0103c6b:	c6 83 b9 1b 00 00 ee 	movb   $0xee,0x1bb9(%ebx)
f0103c72:	c1 e8 10             	shr    $0x10,%eax
f0103c75:	66 89 83 ba 1b 00 00 	mov    %ax,0x1bba(%ebx)
	trap_init_percpu();
f0103c7c:	e8 a8 fc ff ff       	call   f0103929 <trap_init_percpu>
}
f0103c81:	83 c4 1c             	add    $0x1c,%esp
f0103c84:	5b                   	pop    %ebx
f0103c85:	5e                   	pop    %esi
f0103c86:	5f                   	pop    %edi
f0103c87:	5d                   	pop    %ebp
f0103c88:	c3                   	ret    
f0103c89:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
f0103c8d:	66 89 83 52 1a 00 00 	mov    %ax,0x1a52(%ebx)
f0103c94:	e9 5f ff ff ff       	jmp    f0103bf8 <trap_init+0x230>
f0103c99:	0f b6 55 df          	movzbl -0x21(%ebp),%edx
f0103c9d:	c1 e2 07             	shl    $0x7,%edx
f0103ca0:	0f b6 83 51 1a 00 00 	movzbl 0x1a51(%ebx),%eax
f0103ca7:	83 e0 7f             	and    $0x7f,%eax
f0103caa:	09 d0                	or     %edx,%eax
f0103cac:	88 83 51 1a 00 00    	mov    %al,0x1a51(%ebx)
f0103cb2:	e9 4b ff ff ff       	jmp    f0103c02 <trap_init+0x23a>
f0103cb7:	b8 03 00 00 00       	mov    $0x3,%eax
f0103cbc:	83 e0 03             	and    $0x3,%eax
f0103cbf:	c1 e0 05             	shl    $0x5,%eax
f0103cc2:	89 c2                	mov    %eax,%edx
f0103cc4:	0f b6 83 51 1a 00 00 	movzbl 0x1a51(%ebx),%eax
f0103ccb:	83 e0 9f             	and    $0xffffff9f,%eax
f0103cce:	09 d0                	or     %edx,%eax
f0103cd0:	88 83 51 1a 00 00    	mov    %al,0x1a51(%ebx)
f0103cd6:	e9 31 ff ff ff       	jmp    f0103c0c <trap_init+0x244>
f0103cdb:	0f b6 45 de          	movzbl -0x22(%ebp),%eax
f0103cdf:	83 e0 01             	and    $0x1,%eax
f0103ce2:	c1 e0 04             	shl    $0x4,%eax
f0103ce5:	89 c2                	mov    %eax,%edx
f0103ce7:	0f b6 83 51 1a 00 00 	movzbl 0x1a51(%ebx),%eax
f0103cee:	83 e0 ef             	and    $0xffffffef,%eax
f0103cf1:	09 d0                	or     %edx,%eax
f0103cf3:	88 83 51 1a 00 00    	mov    %al,0x1a51(%ebx)
f0103cf9:	e9 18 ff ff ff       	jmp    f0103c16 <trap_init+0x24e>
f0103cfe:	ba 0e 00 00 00       	mov    $0xe,%edx
f0103d03:	83 e2 0f             	and    $0xf,%edx
f0103d06:	0f b6 83 51 1a 00 00 	movzbl 0x1a51(%ebx),%eax
f0103d0d:	83 e0 f0             	and    $0xfffffff0,%eax
f0103d10:	09 d0                	or     %edx,%eax
f0103d12:	88 83 51 1a 00 00    	mov    %al,0x1a51(%ebx)
f0103d18:	e9 03 ff ff ff       	jmp    f0103c20 <trap_init+0x258>
f0103d1d:	0f b6 55 da          	movzbl -0x26(%ebp),%edx
f0103d21:	c1 e2 05             	shl    $0x5,%edx
f0103d24:	0f b6 83 50 1a 00 00 	movzbl 0x1a50(%ebx),%eax
f0103d2b:	83 e0 1f             	and    $0x1f,%eax
f0103d2e:	09 d0                	or     %edx,%eax
f0103d30:	88 83 50 1a 00 00    	mov    %al,0x1a50(%ebx)
f0103d36:	e9 ef fe ff ff       	jmp    f0103c2a <trap_init+0x262>
f0103d3b:	0f b6 55 db          	movzbl -0x25(%ebp),%edx
f0103d3f:	83 e2 1f             	and    $0x1f,%edx
f0103d42:	0f b6 83 50 1a 00 00 	movzbl 0x1a50(%ebx),%eax
f0103d49:	83 e0 e0             	and    $0xffffffe0,%eax
f0103d4c:	09 d0                	or     %edx,%eax
f0103d4e:	88 83 50 1a 00 00    	mov    %al,0x1a50(%ebx)
f0103d54:	e9 db fe ff ff       	jmp    f0103c34 <trap_init+0x26c>
f0103d59:	66 c7 83 4e 1a 00 00 	movw   $0x8,0x1a4e(%ebx)
f0103d60:	08 00 
f0103d62:	e9 d7 fe ff ff       	jmp    f0103c3e <trap_init+0x276>
f0103d67:	0f b7 45 dc          	movzwl -0x24(%ebp),%eax
f0103d6b:	66 89 83 4c 1a 00 00 	mov    %ax,0x1a4c(%ebx)
f0103d72:	e9 d1 fe ff ff       	jmp    f0103c48 <trap_init+0x280>

f0103d77 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103d77:	55                   	push   %ebp
f0103d78:	89 e5                	mov    %esp,%ebp
f0103d7a:	56                   	push   %esi
f0103d7b:	53                   	push   %ebx
f0103d7c:	e8 e6 c3 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103d81:	81 c3 ab bb 07 00    	add    $0x7bbab,%ebx
f0103d87:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103d8a:	83 ec 08             	sub    $0x8,%esp
f0103d8d:	ff 36                	push   (%esi)
f0103d8f:	8d 83 ba 6a f8 ff    	lea    -0x79546(%ebx),%eax
f0103d95:	50                   	push   %eax
f0103d96:	e8 7a fb ff ff       	call   f0103915 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103d9b:	83 c4 08             	add    $0x8,%esp
f0103d9e:	ff 76 04             	push   0x4(%esi)
f0103da1:	8d 83 c9 6a f8 ff    	lea    -0x79537(%ebx),%eax
f0103da7:	50                   	push   %eax
f0103da8:	e8 68 fb ff ff       	call   f0103915 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103dad:	83 c4 08             	add    $0x8,%esp
f0103db0:	ff 76 08             	push   0x8(%esi)
f0103db3:	8d 83 d8 6a f8 ff    	lea    -0x79528(%ebx),%eax
f0103db9:	50                   	push   %eax
f0103dba:	e8 56 fb ff ff       	call   f0103915 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103dbf:	83 c4 08             	add    $0x8,%esp
f0103dc2:	ff 76 0c             	push   0xc(%esi)
f0103dc5:	8d 83 e7 6a f8 ff    	lea    -0x79519(%ebx),%eax
f0103dcb:	50                   	push   %eax
f0103dcc:	e8 44 fb ff ff       	call   f0103915 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103dd1:	83 c4 08             	add    $0x8,%esp
f0103dd4:	ff 76 10             	push   0x10(%esi)
f0103dd7:	8d 83 f6 6a f8 ff    	lea    -0x7950a(%ebx),%eax
f0103ddd:	50                   	push   %eax
f0103dde:	e8 32 fb ff ff       	call   f0103915 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103de3:	83 c4 08             	add    $0x8,%esp
f0103de6:	ff 76 14             	push   0x14(%esi)
f0103de9:	8d 83 05 6b f8 ff    	lea    -0x794fb(%ebx),%eax
f0103def:	50                   	push   %eax
f0103df0:	e8 20 fb ff ff       	call   f0103915 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103df5:	83 c4 08             	add    $0x8,%esp
f0103df8:	ff 76 18             	push   0x18(%esi)
f0103dfb:	8d 83 14 6b f8 ff    	lea    -0x794ec(%ebx),%eax
f0103e01:	50                   	push   %eax
f0103e02:	e8 0e fb ff ff       	call   f0103915 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103e07:	83 c4 08             	add    $0x8,%esp
f0103e0a:	ff 76 1c             	push   0x1c(%esi)
f0103e0d:	8d 83 23 6b f8 ff    	lea    -0x794dd(%ebx),%eax
f0103e13:	50                   	push   %eax
f0103e14:	e8 fc fa ff ff       	call   f0103915 <cprintf>
}
f0103e19:	83 c4 10             	add    $0x10,%esp
f0103e1c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103e1f:	5b                   	pop    %ebx
f0103e20:	5e                   	pop    %esi
f0103e21:	5d                   	pop    %ebp
f0103e22:	c3                   	ret    

f0103e23 <print_trapframe>:
{
f0103e23:	55                   	push   %ebp
f0103e24:	89 e5                	mov    %esp,%ebp
f0103e26:	57                   	push   %edi
f0103e27:	56                   	push   %esi
f0103e28:	53                   	push   %ebx
f0103e29:	83 ec 14             	sub    $0x14,%esp
f0103e2c:	e8 36 c3 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103e31:	81 c3 fb ba 07 00    	add    $0x7bafb,%ebx
f0103e37:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("TRAP frame at %p\n", tf);
f0103e3a:	56                   	push   %esi
f0103e3b:	8d 83 70 6c f8 ff    	lea    -0x79390(%ebx),%eax
f0103e41:	50                   	push   %eax
f0103e42:	e8 ce fa ff ff       	call   f0103915 <cprintf>
	print_regs(&tf->tf_regs);
f0103e47:	89 34 24             	mov    %esi,(%esp)
f0103e4a:	e8 28 ff ff ff       	call   f0103d77 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103e4f:	83 c4 08             	add    $0x8,%esp
f0103e52:	0f b7 46 20          	movzwl 0x20(%esi),%eax
f0103e56:	50                   	push   %eax
f0103e57:	8d 83 74 6b f8 ff    	lea    -0x7948c(%ebx),%eax
f0103e5d:	50                   	push   %eax
f0103e5e:	e8 b2 fa ff ff       	call   f0103915 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103e63:	83 c4 08             	add    $0x8,%esp
f0103e66:	0f b7 46 24          	movzwl 0x24(%esi),%eax
f0103e6a:	50                   	push   %eax
f0103e6b:	8d 83 87 6b f8 ff    	lea    -0x79479(%ebx),%eax
f0103e71:	50                   	push   %eax
f0103e72:	e8 9e fa ff ff       	call   f0103915 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103e77:	8b 56 28             	mov    0x28(%esi),%edx
	if (trapno < ARRAY_SIZE(excnames))
f0103e7a:	83 c4 10             	add    $0x10,%esp
f0103e7d:	83 fa 13             	cmp    $0x13,%edx
f0103e80:	0f 86 e2 00 00 00    	jbe    f0103f68 <print_trapframe+0x145>
		return "System call";
f0103e86:	83 fa 30             	cmp    $0x30,%edx
f0103e89:	8d 83 32 6b f8 ff    	lea    -0x794ce(%ebx),%eax
f0103e8f:	8d 8b 41 6b f8 ff    	lea    -0x794bf(%ebx),%ecx
f0103e95:	0f 44 c1             	cmove  %ecx,%eax
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103e98:	83 ec 04             	sub    $0x4,%esp
f0103e9b:	50                   	push   %eax
f0103e9c:	52                   	push   %edx
f0103e9d:	8d 83 9a 6b f8 ff    	lea    -0x79466(%ebx),%eax
f0103ea3:	50                   	push   %eax
f0103ea4:	e8 6c fa ff ff       	call   f0103915 <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103ea9:	83 c4 10             	add    $0x10,%esp
f0103eac:	39 b3 34 22 00 00    	cmp    %esi,0x2234(%ebx)
f0103eb2:	0f 84 bc 00 00 00    	je     f0103f74 <print_trapframe+0x151>
	cprintf("  err  0x%08x", tf->tf_err);
f0103eb8:	83 ec 08             	sub    $0x8,%esp
f0103ebb:	ff 76 2c             	push   0x2c(%esi)
f0103ebe:	8d 83 bb 6b f8 ff    	lea    -0x79445(%ebx),%eax
f0103ec4:	50                   	push   %eax
f0103ec5:	e8 4b fa ff ff       	call   f0103915 <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f0103eca:	83 c4 10             	add    $0x10,%esp
f0103ecd:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f0103ed1:	0f 85 c2 00 00 00    	jne    f0103f99 <print_trapframe+0x176>
			tf->tf_err & 1 ? "protection" : "not-present");
f0103ed7:	8b 46 2c             	mov    0x2c(%esi),%eax
		cprintf(" [%s, %s, %s]\n",
f0103eda:	a8 01                	test   $0x1,%al
f0103edc:	8d 8b 4d 6b f8 ff    	lea    -0x794b3(%ebx),%ecx
f0103ee2:	8d 93 58 6b f8 ff    	lea    -0x794a8(%ebx),%edx
f0103ee8:	0f 44 ca             	cmove  %edx,%ecx
f0103eeb:	a8 02                	test   $0x2,%al
f0103eed:	8d 93 64 6b f8 ff    	lea    -0x7949c(%ebx),%edx
f0103ef3:	8d bb 6a 6b f8 ff    	lea    -0x79496(%ebx),%edi
f0103ef9:	0f 44 d7             	cmove  %edi,%edx
f0103efc:	a8 04                	test   $0x4,%al
f0103efe:	8d 83 6f 6b f8 ff    	lea    -0x79491(%ebx),%eax
f0103f04:	8d bb 9b 6c f8 ff    	lea    -0x79365(%ebx),%edi
f0103f0a:	0f 44 c7             	cmove  %edi,%eax
f0103f0d:	51                   	push   %ecx
f0103f0e:	52                   	push   %edx
f0103f0f:	50                   	push   %eax
f0103f10:	8d 83 c9 6b f8 ff    	lea    -0x79437(%ebx),%eax
f0103f16:	50                   	push   %eax
f0103f17:	e8 f9 f9 ff ff       	call   f0103915 <cprintf>
f0103f1c:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103f1f:	83 ec 08             	sub    $0x8,%esp
f0103f22:	ff 76 30             	push   0x30(%esi)
f0103f25:	8d 83 d8 6b f8 ff    	lea    -0x79428(%ebx),%eax
f0103f2b:	50                   	push   %eax
f0103f2c:	e8 e4 f9 ff ff       	call   f0103915 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103f31:	83 c4 08             	add    $0x8,%esp
f0103f34:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103f38:	50                   	push   %eax
f0103f39:	8d 83 e7 6b f8 ff    	lea    -0x79419(%ebx),%eax
f0103f3f:	50                   	push   %eax
f0103f40:	e8 d0 f9 ff ff       	call   f0103915 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103f45:	83 c4 08             	add    $0x8,%esp
f0103f48:	ff 76 38             	push   0x38(%esi)
f0103f4b:	8d 83 fa 6b f8 ff    	lea    -0x79406(%ebx),%eax
f0103f51:	50                   	push   %eax
f0103f52:	e8 be f9 ff ff       	call   f0103915 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103f57:	83 c4 10             	add    $0x10,%esp
f0103f5a:	f6 46 34 03          	testb  $0x3,0x34(%esi)
f0103f5e:	75 50                	jne    f0103fb0 <print_trapframe+0x18d>
}
f0103f60:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103f63:	5b                   	pop    %ebx
f0103f64:	5e                   	pop    %esi
f0103f65:	5f                   	pop    %edi
f0103f66:	5d                   	pop    %ebp
f0103f67:	c3                   	ret    
		return excnames[trapno];
f0103f68:	8b 84 93 34 17 00 00 	mov    0x1734(%ebx,%edx,4),%eax
f0103f6f:	e9 24 ff ff ff       	jmp    f0103e98 <print_trapframe+0x75>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103f74:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f0103f78:	0f 85 3a ff ff ff    	jne    f0103eb8 <print_trapframe+0x95>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103f7e:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103f81:	83 ec 08             	sub    $0x8,%esp
f0103f84:	50                   	push   %eax
f0103f85:	8d 83 ac 6b f8 ff    	lea    -0x79454(%ebx),%eax
f0103f8b:	50                   	push   %eax
f0103f8c:	e8 84 f9 ff ff       	call   f0103915 <cprintf>
f0103f91:	83 c4 10             	add    $0x10,%esp
f0103f94:	e9 1f ff ff ff       	jmp    f0103eb8 <print_trapframe+0x95>
		cprintf("\n");
f0103f99:	83 ec 0c             	sub    $0xc,%esp
f0103f9c:	8d 83 0a 62 f8 ff    	lea    -0x79df6(%ebx),%eax
f0103fa2:	50                   	push   %eax
f0103fa3:	e8 6d f9 ff ff       	call   f0103915 <cprintf>
f0103fa8:	83 c4 10             	add    $0x10,%esp
f0103fab:	e9 6f ff ff ff       	jmp    f0103f1f <print_trapframe+0xfc>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103fb0:	83 ec 08             	sub    $0x8,%esp
f0103fb3:	ff 76 3c             	push   0x3c(%esi)
f0103fb6:	8d 83 09 6c f8 ff    	lea    -0x793f7(%ebx),%eax
f0103fbc:	50                   	push   %eax
f0103fbd:	e8 53 f9 ff ff       	call   f0103915 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103fc2:	83 c4 08             	add    $0x8,%esp
f0103fc5:	0f b7 46 40          	movzwl 0x40(%esi),%eax
f0103fc9:	50                   	push   %eax
f0103fca:	8d 83 18 6c f8 ff    	lea    -0x793e8(%ebx),%eax
f0103fd0:	50                   	push   %eax
f0103fd1:	e8 3f f9 ff ff       	call   f0103915 <cprintf>
f0103fd6:	83 c4 10             	add    $0x10,%esp
}
f0103fd9:	eb 85                	jmp    f0103f60 <print_trapframe+0x13d>

f0103fdb <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103fdb:	55                   	push   %ebp
f0103fdc:	89 e5                	mov    %esp,%ebp
f0103fde:	57                   	push   %edi
f0103fdf:	56                   	push   %esi
f0103fe0:	53                   	push   %ebx
f0103fe1:	83 ec 0c             	sub    $0xc,%esp
f0103fe4:	e8 7e c1 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103fe9:	81 c3 43 b9 07 00    	add    $0x7b943,%ebx
f0103fef:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ff2:	0f 20 d0             	mov    %cr2,%eax
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs&3) == 0) panic("kernel-mode page fault");
f0103ff5:	f6 46 34 03          	testb  $0x3,0x34(%esi)
f0103ff9:	74 38                	je     f0104033 <page_fault_handler+0x58>
	
	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103ffb:	ff 76 30             	push   0x30(%esi)
f0103ffe:	50                   	push   %eax
f0103fff:	c7 c7 50 13 18 f0    	mov    $0xf0181350,%edi
f0104005:	8b 07                	mov    (%edi),%eax
f0104007:	ff 70 48             	push   0x48(%eax)
f010400a:	8d 83 e8 6d f8 ff    	lea    -0x79218(%ebx),%eax
f0104010:	50                   	push   %eax
f0104011:	e8 ff f8 ff ff       	call   f0103915 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0104016:	89 34 24             	mov    %esi,(%esp)
f0104019:	e8 05 fe ff ff       	call   f0103e23 <print_trapframe>
	env_destroy(curenv);
f010401e:	83 c4 04             	add    $0x4,%esp
f0104021:	ff 37                	push   (%edi)
f0104023:	e8 94 f7 ff ff       	call   f01037bc <env_destroy>
}
f0104028:	83 c4 10             	add    $0x10,%esp
f010402b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010402e:	5b                   	pop    %ebx
f010402f:	5e                   	pop    %esi
f0104030:	5f                   	pop    %edi
f0104031:	5d                   	pop    %ebp
f0104032:	c3                   	ret    
	if ((tf->tf_cs&3) == 0) panic("kernel-mode page fault");
f0104033:	83 ec 04             	sub    $0x4,%esp
f0104036:	8d 83 2b 6c f8 ff    	lea    -0x793d5(%ebx),%eax
f010403c:	50                   	push   %eax
f010403d:	68 e5 00 00 00       	push   $0xe5
f0104042:	8d 83 42 6c f8 ff    	lea    -0x793be(%ebx),%eax
f0104048:	50                   	push   %eax
f0104049:	e8 63 c0 ff ff       	call   f01000b1 <_panic>

f010404e <trap>:
{
f010404e:	55                   	push   %ebp
f010404f:	89 e5                	mov    %esp,%ebp
f0104051:	57                   	push   %edi
f0104052:	56                   	push   %esi
f0104053:	53                   	push   %ebx
f0104054:	83 ec 0c             	sub    $0xc,%esp
f0104057:	e8 0b c1 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010405c:	81 c3 d0 b8 07 00    	add    $0x7b8d0,%ebx
f0104062:	8b 75 08             	mov    0x8(%ebp),%esi
	asm volatile("cld" ::: "cc");
f0104065:	fc                   	cld    
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0104066:	9c                   	pushf  
f0104067:	58                   	pop    %eax
	assert(!(read_eflags() & FL_IF));
f0104068:	f6 c4 02             	test   $0x2,%ah
f010406b:	74 1f                	je     f010408c <trap+0x3e>
f010406d:	8d 83 4e 6c f8 ff    	lea    -0x793b2(%ebx),%eax
f0104073:	50                   	push   %eax
f0104074:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010407a:	50                   	push   %eax
f010407b:	68 bd 00 00 00       	push   $0xbd
f0104080:	8d 83 42 6c f8 ff    	lea    -0x793be(%ebx),%eax
f0104086:	50                   	push   %eax
f0104087:	e8 25 c0 ff ff       	call   f01000b1 <_panic>
	cprintf("Incoming TRAP frame at %p\n", tf);
f010408c:	83 ec 08             	sub    $0x8,%esp
f010408f:	56                   	push   %esi
f0104090:	8d 83 67 6c f8 ff    	lea    -0x79399(%ebx),%eax
f0104096:	50                   	push   %eax
f0104097:	e8 79 f8 ff ff       	call   f0103915 <cprintf>
	if ((tf->tf_cs & 3) == 3) {
f010409c:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01040a0:	83 e0 03             	and    $0x3,%eax
f01040a3:	83 c4 10             	add    $0x10,%esp
f01040a6:	66 83 f8 03          	cmp    $0x3,%ax
f01040aa:	75 21                	jne    f01040cd <trap+0x7f>
		assert(curenv);
f01040ac:	c7 c0 50 13 18 f0    	mov    $0xf0181350,%eax
f01040b2:	8b 00                	mov    (%eax),%eax
f01040b4:	85 c0                	test   %eax,%eax
f01040b6:	0f 84 94 00 00 00    	je     f0104150 <trap+0x102>
		curenv->env_tf = *tf;
f01040bc:	b9 11 00 00 00       	mov    $0x11,%ecx
f01040c1:	89 c7                	mov    %eax,%edi
f01040c3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		tf = &curenv->env_tf;
f01040c5:	c7 c0 50 13 18 f0    	mov    $0xf0181350,%eax
f01040cb:	8b 30                	mov    (%eax),%esi
	last_tf = tf;
f01040cd:	89 b3 34 22 00 00    	mov    %esi,0x2234(%ebx)
	if (tf->tf_trapno == T_PGFLT) 
f01040d3:	8b 46 28             	mov    0x28(%esi),%eax
f01040d6:	83 f8 0e             	cmp    $0xe,%eax
f01040d9:	0f 84 90 00 00 00    	je     f010416f <trap+0x121>
	if (tf->tf_trapno == T_BRKPT) 
f01040df:	83 f8 03             	cmp    $0x3,%eax
f01040e2:	0f 84 95 00 00 00    	je     f010417d <trap+0x12f>
	if (tf->tf_trapno == T_SYSCALL) 
f01040e8:	83 f8 30             	cmp    $0x30,%eax
f01040eb:	0f 84 9a 00 00 00    	je     f010418b <trap+0x13d>
	print_trapframe(tf);
f01040f1:	83 ec 0c             	sub    $0xc,%esp
f01040f4:	56                   	push   %esi
f01040f5:	e8 29 fd ff ff       	call   f0103e23 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01040fa:	83 c4 10             	add    $0x10,%esp
f01040fd:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0104102:	0f 84 a7 00 00 00    	je     f01041af <trap+0x161>
		env_destroy(curenv);
f0104108:	83 ec 0c             	sub    $0xc,%esp
f010410b:	c7 c0 50 13 18 f0    	mov    $0xf0181350,%eax
f0104111:	ff 30                	push   (%eax)
f0104113:	e8 a4 f6 ff ff       	call   f01037bc <env_destroy>
		return;
f0104118:	83 c4 10             	add    $0x10,%esp
	assert(curenv && curenv->env_status == ENV_RUNNING);
f010411b:	c7 c0 50 13 18 f0    	mov    $0xf0181350,%eax
f0104121:	8b 00                	mov    (%eax),%eax
f0104123:	85 c0                	test   %eax,%eax
f0104125:	74 0a                	je     f0104131 <trap+0xe3>
f0104127:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010412b:	0f 84 99 00 00 00    	je     f01041ca <trap+0x17c>
f0104131:	8d 83 0c 6e f8 ff    	lea    -0x791f4(%ebx),%eax
f0104137:	50                   	push   %eax
f0104138:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010413e:	50                   	push   %eax
f010413f:	68 d5 00 00 00       	push   $0xd5
f0104144:	8d 83 42 6c f8 ff    	lea    -0x793be(%ebx),%eax
f010414a:	50                   	push   %eax
f010414b:	e8 61 bf ff ff       	call   f01000b1 <_panic>
		assert(curenv);
f0104150:	8d 83 82 6c f8 ff    	lea    -0x7937e(%ebx),%eax
f0104156:	50                   	push   %eax
f0104157:	8d 83 6f 5f f8 ff    	lea    -0x7a091(%ebx),%eax
f010415d:	50                   	push   %eax
f010415e:	68 c3 00 00 00       	push   $0xc3
f0104163:	8d 83 42 6c f8 ff    	lea    -0x793be(%ebx),%eax
f0104169:	50                   	push   %eax
f010416a:	e8 42 bf ff ff       	call   f01000b1 <_panic>
		page_fault_handler(tf);
f010416f:	83 ec 0c             	sub    $0xc,%esp
f0104172:	56                   	push   %esi
f0104173:	e8 63 fe ff ff       	call   f0103fdb <page_fault_handler>
		return;
f0104178:	83 c4 10             	add    $0x10,%esp
f010417b:	eb 9e                	jmp    f010411b <trap+0xcd>
		monitor(tf);
f010417d:	83 ec 0c             	sub    $0xc,%esp
f0104180:	56                   	push   %esi
f0104181:	e8 2d c7 ff ff       	call   f01008b3 <monitor>
		return;
f0104186:	83 c4 10             	add    $0x10,%esp
f0104189:	eb 90                	jmp    f010411b <trap+0xcd>
		tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx, tf->tf_regs.reg_ebx, tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
f010418b:	83 ec 08             	sub    $0x8,%esp
f010418e:	ff 76 04             	push   0x4(%esi)
f0104191:	ff 36                	push   (%esi)
f0104193:	ff 76 10             	push   0x10(%esi)
f0104196:	ff 76 18             	push   0x18(%esi)
f0104199:	ff 76 14             	push   0x14(%esi)
f010419c:	ff 76 1c             	push   0x1c(%esi)
f010419f:	e8 95 00 00 00       	call   f0104239 <syscall>
f01041a4:	89 46 1c             	mov    %eax,0x1c(%esi)
		return;
f01041a7:	83 c4 20             	add    $0x20,%esp
f01041aa:	e9 6c ff ff ff       	jmp    f010411b <trap+0xcd>
		panic("unhandled trap in kernel");
f01041af:	83 ec 04             	sub    $0x4,%esp
f01041b2:	8d 83 89 6c f8 ff    	lea    -0x79377(%ebx),%eax
f01041b8:	50                   	push   %eax
f01041b9:	68 ac 00 00 00       	push   $0xac
f01041be:	8d 83 42 6c f8 ff    	lea    -0x793be(%ebx),%eax
f01041c4:	50                   	push   %eax
f01041c5:	e8 e7 be ff ff       	call   f01000b1 <_panic>
	env_run(curenv);
f01041ca:	83 ec 0c             	sub    $0xc,%esp
f01041cd:	50                   	push   %eax
f01041ce:	e8 57 f6 ff ff       	call   f010382a <env_run>
f01041d3:	90                   	nop

f01041d4 <v0>:
.data
	.p2align 2
	.globl vectors
vectors:
.text
	NOEC(v0, 0)
f01041d4:	6a 00                	push   $0x0
f01041d6:	6a 00                	push   $0x0
f01041d8:	eb 4e                	jmp    f0104228 <_alltraps>

f01041da <v1>:
	NOEC(v1, 1)
f01041da:	6a 00                	push   $0x0
f01041dc:	6a 01                	push   $0x1
f01041de:	eb 48                	jmp    f0104228 <_alltraps>

f01041e0 <v3>:
	EMPTY()
	NOEC(v3, 3)
f01041e0:	6a 00                	push   $0x0
f01041e2:	6a 03                	push   $0x3
f01041e4:	eb 42                	jmp    f0104228 <_alltraps>

f01041e6 <v4>:
	NOEC(v4, 4)
f01041e6:	6a 00                	push   $0x0
f01041e8:	6a 04                	push   $0x4
f01041ea:	eb 3c                	jmp    f0104228 <_alltraps>

f01041ec <v5>:
	NOEC(v5, 5)
f01041ec:	6a 00                	push   $0x0
f01041ee:	6a 05                	push   $0x5
f01041f0:	eb 36                	jmp    f0104228 <_alltraps>

f01041f2 <v6>:
	NOEC(v6, 6)
f01041f2:	6a 00                	push   $0x0
f01041f4:	6a 06                	push   $0x6
f01041f6:	eb 30                	jmp    f0104228 <_alltraps>

f01041f8 <v7>:
	NOEC(v7, 7)
f01041f8:	6a 00                	push   $0x0
f01041fa:	6a 07                	push   $0x7
f01041fc:	eb 2a                	jmp    f0104228 <_alltraps>

f01041fe <v8>:
	EC(v8, 8)
f01041fe:	6a 08                	push   $0x8
f0104200:	eb 26                	jmp    f0104228 <_alltraps>

f0104202 <v9>:
	NOEC(v9, 9)
f0104202:	6a 00                	push   $0x0
f0104204:	6a 09                	push   $0x9
f0104206:	eb 20                	jmp    f0104228 <_alltraps>

f0104208 <v10>:
	EC(v10, 10)
f0104208:	6a 0a                	push   $0xa
f010420a:	eb 1c                	jmp    f0104228 <_alltraps>

f010420c <v11>:
	EC(v11, 11)
f010420c:	6a 0b                	push   $0xb
f010420e:	eb 18                	jmp    f0104228 <_alltraps>

f0104210 <v12>:
	EC(v12, 12)
f0104210:	6a 0c                	push   $0xc
f0104212:	eb 14                	jmp    f0104228 <_alltraps>

f0104214 <v13>:
	EC(v13, 13)
f0104214:	6a 0d                	push   $0xd
f0104216:	eb 10                	jmp    f0104228 <_alltraps>

f0104218 <v14>:
	EC(v14, 14)
f0104218:	6a 0e                	push   $0xe
f010421a:	eb 0c                	jmp    f0104228 <_alltraps>

f010421c <v16>:
	EMPTY()
	NOEC(v16, 16)
f010421c:	6a 00                	push   $0x0
f010421e:	6a 10                	push   $0x10
f0104220:	eb 06                	jmp    f0104228 <_alltraps>

f0104222 <v48>:
.data
	.space 124
.text
	NOEC(v48, 48)
f0104222:	6a 00                	push   $0x0
f0104224:	6a 30                	push   $0x30
f0104226:	eb 00                	jmp    f0104228 <_alltraps>

f0104228 <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds
f0104228:	1e                   	push   %ds
	pushl %es
f0104229:	06                   	push   %es
	pushal
f010422a:	60                   	pusha  
	movw $GD_KD, %ax
f010422b:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f010422f:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0104231:	8e c0                	mov    %eax,%es
	pushl %esp
f0104233:	54                   	push   %esp
	call trap
f0104234:	e8 15 fe ff ff       	call   f010404e <trap>

f0104239 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104239:	55                   	push   %ebp
f010423a:	89 e5                	mov    %esp,%ebp
f010423c:	53                   	push   %ebx
f010423d:	83 ec 14             	sub    $0x14,%esp
f0104240:	e8 22 bf ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104245:	81 c3 e7 b6 07 00    	add    $0x7b6e7,%ebx
f010424b:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	int ret = 0;
	switch (syscallno) 
f010424e:	83 f8 02             	cmp    $0x2,%eax
f0104251:	0f 84 bf 00 00 00    	je     f0104316 <syscall+0xdd>
f0104257:	83 f8 02             	cmp    $0x2,%eax
f010425a:	77 0b                	ja     f0104267 <syscall+0x2e>
f010425c:	85 c0                	test   %eax,%eax
f010425e:	74 6e                	je     f01042ce <syscall+0x95>
	return cons_getc();
f0104260:	e8 04 c3 ff ff       	call   f0100569 <cons_getc>
	{
		case SYS_cputs: sys_cputs((char*)a1, a2);
			ret = 0;
			break;
		case SYS_cgetc: ret = sys_cgetc();
			break;
f0104265:	eb 62                	jmp    f01042c9 <syscall+0x90>
	switch (syscallno) 
f0104267:	83 f8 03             	cmp    $0x3,%eax
f010426a:	75 58                	jne    f01042c4 <syscall+0x8b>
	if ((r = envid2env(envid, &e, 1)) < 0)
f010426c:	83 ec 04             	sub    $0x4,%esp
f010426f:	6a 01                	push   $0x1
f0104271:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104274:	50                   	push   %eax
f0104275:	ff 75 0c             	push   0xc(%ebp)
f0104278:	e8 77 ef ff ff       	call   f01031f4 <envid2env>
f010427d:	83 c4 10             	add    $0x10,%esp
f0104280:	85 c0                	test   %eax,%eax
f0104282:	78 39                	js     f01042bd <syscall+0x84>
	if (e == curenv)
f0104284:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104287:	c7 c0 50 13 18 f0    	mov    $0xf0181350,%eax
f010428d:	8b 00                	mov    (%eax),%eax
f010428f:	39 c2                	cmp    %eax,%edx
f0104291:	0f 84 8c 00 00 00    	je     f0104323 <syscall+0xea>
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104297:	83 ec 04             	sub    $0x4,%esp
f010429a:	ff 72 48             	push   0x48(%edx)
f010429d:	ff 70 48             	push   0x48(%eax)
f01042a0:	8d 83 58 6e f8 ff    	lea    -0x791a8(%ebx),%eax
f01042a6:	50                   	push   %eax
f01042a7:	e8 69 f6 ff ff       	call   f0103915 <cprintf>
f01042ac:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01042af:	83 ec 0c             	sub    $0xc,%esp
f01042b2:	ff 75 f4             	push   -0xc(%ebp)
f01042b5:	e8 02 f5 ff ff       	call   f01037bc <env_destroy>
	return 0;
f01042ba:	83 c4 10             	add    $0x10,%esp
		case SYS_getenvid: ret = sys_getenvid();
			break;
		case SYS_env_destroy: sys_env_destroy(a1);
			ret = 0;
f01042bd:	b8 00 00 00 00       	mov    $0x0,%eax
			break;
		default: ret = -E_INVAL;
	}
	return ret;
f01042c2:	eb 05                	jmp    f01042c9 <syscall+0x90>
	switch (syscallno) 
f01042c4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
f01042c9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01042cc:	c9                   	leave  
f01042cd:	c3                   	ret    
	envid2env(sys_getenvid(), &e, 1);
f01042ce:	83 ec 04             	sub    $0x4,%esp
f01042d1:	6a 01                	push   $0x1
f01042d3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01042d6:	50                   	push   %eax
	return curenv->env_id;
f01042d7:	c7 c0 50 13 18 f0    	mov    $0xf0181350,%eax
f01042dd:	8b 00                	mov    (%eax),%eax
	envid2env(sys_getenvid(), &e, 1);
f01042df:	ff 70 48             	push   0x48(%eax)
f01042e2:	e8 0d ef ff ff       	call   f01031f4 <envid2env>
	user_mem_assert(e, s, len, PTE_U);
f01042e7:	6a 04                	push   $0x4
f01042e9:	ff 75 10             	push   0x10(%ebp)
f01042ec:	ff 75 0c             	push   0xc(%ebp)
f01042ef:	ff 75 f4             	push   -0xc(%ebp)
f01042f2:	e8 1b ee ff ff       	call   f0103112 <user_mem_assert>
	cprintf("%.*s", len, s);
f01042f7:	83 c4 1c             	add    $0x1c,%esp
f01042fa:	ff 75 0c             	push   0xc(%ebp)
f01042fd:	ff 75 10             	push   0x10(%ebp)
f0104300:	8d 83 38 6e f8 ff    	lea    -0x791c8(%ebx),%eax
f0104306:	50                   	push   %eax
f0104307:	e8 09 f6 ff ff       	call   f0103915 <cprintf>
}
f010430c:	83 c4 10             	add    $0x10,%esp
			ret = 0;
f010430f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104314:	eb b3                	jmp    f01042c9 <syscall+0x90>
	return curenv->env_id;
f0104316:	c7 c0 50 13 18 f0    	mov    $0xf0181350,%eax
f010431c:	8b 00                	mov    (%eax),%eax
f010431e:	8b 40 48             	mov    0x48(%eax),%eax
			break;
f0104321:	eb a6                	jmp    f01042c9 <syscall+0x90>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104323:	83 ec 08             	sub    $0x8,%esp
f0104326:	ff 70 48             	push   0x48(%eax)
f0104329:	8d 83 3d 6e f8 ff    	lea    -0x791c3(%ebx),%eax
f010432f:	50                   	push   %eax
f0104330:	e8 e0 f5 ff ff       	call   f0103915 <cprintf>
f0104335:	83 c4 10             	add    $0x10,%esp
f0104338:	e9 72 ff ff ff       	jmp    f01042af <syscall+0x76>

f010433d <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010433d:	55                   	push   %ebp
f010433e:	89 e5                	mov    %esp,%ebp
f0104340:	57                   	push   %edi
f0104341:	56                   	push   %esi
f0104342:	53                   	push   %ebx
f0104343:	83 ec 14             	sub    $0x14,%esp
f0104346:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104349:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010434c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010434f:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104352:	8b 1a                	mov    (%edx),%ebx
f0104354:	8b 01                	mov    (%ecx),%eax
f0104356:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104359:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104360:	eb 2f                	jmp    f0104391 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0104362:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0104365:	39 c3                	cmp    %eax,%ebx
f0104367:	7f 4e                	jg     f01043b7 <stab_binsearch+0x7a>
f0104369:	0f b6 0a             	movzbl (%edx),%ecx
f010436c:	83 ea 0c             	sub    $0xc,%edx
f010436f:	39 f1                	cmp    %esi,%ecx
f0104371:	75 ef                	jne    f0104362 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104373:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104376:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104379:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010437d:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104380:	73 3a                	jae    f01043bc <stab_binsearch+0x7f>
			*region_left = m;
f0104382:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104385:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104387:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f010438a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0104391:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104394:	7f 53                	jg     f01043e9 <stab_binsearch+0xac>
		int true_m = (l + r) / 2, m = true_m;
f0104396:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104399:	8d 14 03             	lea    (%ebx,%eax,1),%edx
f010439c:	89 d0                	mov    %edx,%eax
f010439e:	c1 e8 1f             	shr    $0x1f,%eax
f01043a1:	01 d0                	add    %edx,%eax
f01043a3:	89 c7                	mov    %eax,%edi
f01043a5:	d1 ff                	sar    %edi
f01043a7:	83 e0 fe             	and    $0xfffffffe,%eax
f01043aa:	01 f8                	add    %edi,%eax
f01043ac:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01043af:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f01043b3:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f01043b5:	eb ae                	jmp    f0104365 <stab_binsearch+0x28>
			l = true_m + 1;
f01043b7:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f01043ba:	eb d5                	jmp    f0104391 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f01043bc:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01043bf:	76 14                	jbe    f01043d5 <stab_binsearch+0x98>
			*region_right = m - 1;
f01043c1:	83 e8 01             	sub    $0x1,%eax
f01043c4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01043c7:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01043ca:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f01043cc:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01043d3:	eb bc                	jmp    f0104391 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01043d5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01043d8:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f01043da:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01043de:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f01043e0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01043e7:	eb a8                	jmp    f0104391 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f01043e9:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01043ed:	75 15                	jne    f0104404 <stab_binsearch+0xc7>
		*region_right = *region_left - 1;
f01043ef:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01043f2:	8b 00                	mov    (%eax),%eax
f01043f4:	83 e8 01             	sub    $0x1,%eax
f01043f7:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01043fa:	89 07                	mov    %eax,(%edi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f01043fc:	83 c4 14             	add    $0x14,%esp
f01043ff:	5b                   	pop    %ebx
f0104400:	5e                   	pop    %esi
f0104401:	5f                   	pop    %edi
f0104402:	5d                   	pop    %ebp
f0104403:	c3                   	ret    
		for (l = *region_right;
f0104404:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104407:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104409:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010440c:	8b 0f                	mov    (%edi),%ecx
f010440e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104411:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0104414:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
f0104418:	39 c1                	cmp    %eax,%ecx
f010441a:	7d 0f                	jge    f010442b <stab_binsearch+0xee>
f010441c:	0f b6 1a             	movzbl (%edx),%ebx
f010441f:	83 ea 0c             	sub    $0xc,%edx
f0104422:	39 f3                	cmp    %esi,%ebx
f0104424:	74 05                	je     f010442b <stab_binsearch+0xee>
		     l--)
f0104426:	83 e8 01             	sub    $0x1,%eax
f0104429:	eb ed                	jmp    f0104418 <stab_binsearch+0xdb>
		*region_left = l;
f010442b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010442e:	89 07                	mov    %eax,(%edi)
}
f0104430:	eb ca                	jmp    f01043fc <stab_binsearch+0xbf>

f0104432 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104432:	55                   	push   %ebp
f0104433:	89 e5                	mov    %esp,%ebp
f0104435:	57                   	push   %edi
f0104436:	56                   	push   %esi
f0104437:	53                   	push   %ebx
f0104438:	83 ec 4c             	sub    $0x4c,%esp
f010443b:	e8 27 bd ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104440:	81 c3 ec b4 07 00    	add    $0x7b4ec,%ebx
f0104446:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104449:	8d 83 70 6e f8 ff    	lea    -0x79190(%ebx),%eax
f010444f:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f0104451:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0104458:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f010445b:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0104462:	8b 45 08             	mov    0x8(%ebp),%eax
f0104465:	89 46 10             	mov    %eax,0x10(%esi)
	info->eip_fn_narg = 0;
f0104468:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010446f:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0104474:	0f 86 33 01 00 00    	jbe    f01045ad <debuginfo_eip+0x17b>
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f010447a:	c7 c0 4f 2b 11 f0    	mov    $0xf0112b4f,%eax
f0104480:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0104483:	c7 c0 c9 ed 10 f0    	mov    $0xf010edc9,%eax
f0104489:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stab_end = __STAB_END__;
f010448c:	c7 c7 c8 ed 10 f0    	mov    $0xf010edc8,%edi
		stabs = __STAB_BEGIN__;
f0104492:	c7 c0 98 69 10 f0    	mov    $0xf0106998,%eax
f0104498:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr, PTE_U))
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010449b:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f010449e:	39 4d bc             	cmp    %ecx,-0x44(%ebp)
f01044a1:	0f 83 1f 02 00 00    	jae    f01046c6 <debuginfo_eip+0x294>
f01044a7:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f01044ab:	0f 85 1c 02 00 00    	jne    f01046cd <debuginfo_eip+0x29b>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01044b1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01044b8:	2b 7d c4             	sub    -0x3c(%ebp),%edi
f01044bb:	c1 ff 02             	sar    $0x2,%edi
f01044be:	69 c7 ab aa aa aa    	imul   $0xaaaaaaab,%edi,%eax
f01044c4:	83 e8 01             	sub    $0x1,%eax
f01044c7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01044ca:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01044cd:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01044d0:	83 ec 08             	sub    $0x8,%esp
f01044d3:	ff 75 08             	push   0x8(%ebp)
f01044d6:	6a 64                	push   $0x64
f01044d8:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01044db:	e8 5d fe ff ff       	call   f010433d <stab_binsearch>
	if (lfile == 0)
f01044e0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01044e3:	83 c4 10             	add    $0x10,%esp
f01044e6:	85 ff                	test   %edi,%edi
f01044e8:	0f 84 e6 01 00 00    	je     f01046d4 <debuginfo_eip+0x2a2>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01044ee:	89 7d dc             	mov    %edi,-0x24(%ebp)
	rfun = rfile;
f01044f1:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01044f4:	89 55 b8             	mov    %edx,-0x48(%ebp)
f01044f7:	89 55 d8             	mov    %edx,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01044fa:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01044fd:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104500:	83 ec 08             	sub    $0x8,%esp
f0104503:	ff 75 08             	push   0x8(%ebp)
f0104506:	6a 24                	push   $0x24
f0104508:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010450b:	e8 2d fe ff ff       	call   f010433d <stab_binsearch>

	if (lfun <= rfun) {
f0104510:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104513:	89 55 b4             	mov    %edx,-0x4c(%ebp)
f0104516:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104519:	89 45 b0             	mov    %eax,-0x50(%ebp)
f010451c:	83 c4 10             	add    $0x10,%esp
f010451f:	39 c2                	cmp    %eax,%edx
f0104521:	0f 8f 12 01 00 00    	jg     f0104639 <debuginfo_eip+0x207>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104527:	8d 04 52             	lea    (%edx,%edx,2),%eax
f010452a:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f010452d:	8d 14 82             	lea    (%edx,%eax,4),%edx
f0104530:	8b 02                	mov    (%edx),%eax
f0104532:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0104535:	2b 4d bc             	sub    -0x44(%ebp),%ecx
f0104538:	39 c8                	cmp    %ecx,%eax
f010453a:	73 06                	jae    f0104542 <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010453c:	03 45 bc             	add    -0x44(%ebp),%eax
f010453f:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104542:	8b 42 08             	mov    0x8(%edx),%eax
		addr -= info->eip_fn_addr;
f0104545:	29 45 08             	sub    %eax,0x8(%ebp)
f0104548:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f010454b:	8b 4d b0             	mov    -0x50(%ebp),%ecx
f010454e:	89 4d b8             	mov    %ecx,-0x48(%ebp)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104551:	89 46 10             	mov    %eax,0x10(%esi)
		// Search within the function definition for the line number.
		lline = lfun;
f0104554:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		rline = rfun;
f0104557:	8b 45 b8             	mov    -0x48(%ebp),%eax
f010455a:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010455d:	83 ec 08             	sub    $0x8,%esp
f0104560:	6a 3a                	push   $0x3a
f0104562:	ff 76 08             	push   0x8(%esi)
f0104565:	e8 d6 09 00 00       	call   f0104f40 <strfind>
f010456a:	2b 46 08             	sub    0x8(%esi),%eax
f010456d:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0104570:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104573:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104576:	83 c4 08             	add    $0x8,%esp
f0104579:	ff 75 08             	push   0x8(%ebp)
f010457c:	6a 44                	push   $0x44
f010457e:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104581:	89 d8                	mov    %ebx,%eax
f0104583:	e8 b5 fd ff ff       	call   f010433d <stab_binsearch>
	if (lline <= rline) 
f0104588:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010458b:	83 c4 10             	add    $0x10,%esp
f010458e:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0104591:	0f 8f 44 01 00 00    	jg     f01046db <debuginfo_eip+0x2a9>
	{
    		info->eip_line = stabs[lline].n_desc;
f0104597:	89 c2                	mov    %eax,%edx
f0104599:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010459c:	0f b7 4c 83 06       	movzwl 0x6(%ebx,%eax,4),%ecx
f01045a1:	89 4e 04             	mov    %ecx,0x4(%esi)
f01045a4:	8d 44 83 04          	lea    0x4(%ebx,%eax,4),%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01045a8:	e9 9c 00 00 00       	jmp    f0104649 <debuginfo_eip+0x217>
		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
f01045ad:	6a 04                	push   $0x4
f01045af:	6a 10                	push   $0x10
f01045b1:	68 00 00 20 00       	push   $0x200000
f01045b6:	c7 c0 50 13 18 f0    	mov    $0xf0181350,%eax
f01045bc:	ff 30                	push   (%eax)
f01045be:	e8 be ea ff ff       	call   f0103081 <user_mem_check>
f01045c3:	83 c4 10             	add    $0x10,%esp
f01045c6:	85 c0                	test   %eax,%eax
f01045c8:	0f 85 ea 00 00 00    	jne    f01046b8 <debuginfo_eip+0x286>
		stabs = usd->stabs;
f01045ce:	8b 15 00 00 20 00    	mov    0x200000,%edx
f01045d4:	89 55 c4             	mov    %edx,-0x3c(%ebp)
		stab_end = usd->stab_end;
f01045d7:	8b 3d 04 00 20 00    	mov    0x200004,%edi
		stabstr = usd->stabstr;
f01045dd:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f01045e3:	89 4d bc             	mov    %ecx,-0x44(%ebp)
		stabstr_end = usd->stabstr_end;
f01045e6:	a1 0c 00 20 00       	mov    0x20000c,%eax
f01045eb:	89 45 c0             	mov    %eax,-0x40(%ebp)
		if (user_mem_check(curenv, stabs, sizeof(struct Stab), PTE_U))
f01045ee:	6a 04                	push   $0x4
f01045f0:	6a 0c                	push   $0xc
f01045f2:	52                   	push   %edx
f01045f3:	c7 c0 50 13 18 f0    	mov    $0xf0181350,%eax
f01045f9:	ff 30                	push   (%eax)
f01045fb:	e8 81 ea ff ff       	call   f0103081 <user_mem_check>
f0104600:	83 c4 10             	add    $0x10,%esp
f0104603:	85 c0                	test   %eax,%eax
f0104605:	0f 85 b4 00 00 00    	jne    f01046bf <debuginfo_eip+0x28d>
		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr, PTE_U))
f010460b:	6a 04                	push   $0x4
f010460d:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0104610:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0104613:	29 c8                	sub    %ecx,%eax
f0104615:	50                   	push   %eax
f0104616:	51                   	push   %ecx
f0104617:	c7 c0 50 13 18 f0    	mov    $0xf0181350,%eax
f010461d:	ff 30                	push   (%eax)
f010461f:	e8 5d ea ff ff       	call   f0103081 <user_mem_check>
f0104624:	83 c4 10             	add    $0x10,%esp
f0104627:	85 c0                	test   %eax,%eax
f0104629:	0f 84 6c fe ff ff    	je     f010449b <debuginfo_eip+0x69>
			return -1;
f010462f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104634:	e9 ae 00 00 00       	jmp    f01046e7 <debuginfo_eip+0x2b5>
f0104639:	8b 45 08             	mov    0x8(%ebp),%eax
f010463c:	89 fa                	mov    %edi,%edx
f010463e:	e9 0e ff ff ff       	jmp    f0104551 <debuginfo_eip+0x11f>
f0104643:	83 ea 01             	sub    $0x1,%edx
f0104646:	83 e8 0c             	sub    $0xc,%eax
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104649:	39 d7                	cmp    %edx,%edi
f010464b:	7f 2e                	jg     f010467b <debuginfo_eip+0x249>
	       && stabs[lline].n_type != N_SOL
f010464d:	0f b6 08             	movzbl (%eax),%ecx
f0104650:	80 f9 84             	cmp    $0x84,%cl
f0104653:	74 0b                	je     f0104660 <debuginfo_eip+0x22e>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104655:	80 f9 64             	cmp    $0x64,%cl
f0104658:	75 e9                	jne    f0104643 <debuginfo_eip+0x211>
f010465a:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f010465e:	74 e3                	je     f0104643 <debuginfo_eip+0x211>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104660:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0104663:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104666:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104669:	8b 45 c0             	mov    -0x40(%ebp),%eax
f010466c:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010466f:	29 f8                	sub    %edi,%eax
f0104671:	39 c2                	cmp    %eax,%edx
f0104673:	73 06                	jae    f010467b <debuginfo_eip+0x249>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104675:	89 f8                	mov    %edi,%eax
f0104677:	01 d0                	add    %edx,%eax
f0104679:	89 06                	mov    %eax,(%esi)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010467b:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0104680:	8b 7d b4             	mov    -0x4c(%ebp),%edi
f0104683:	8b 5d b0             	mov    -0x50(%ebp),%ebx
f0104686:	39 df                	cmp    %ebx,%edi
f0104688:	7d 5d                	jge    f01046e7 <debuginfo_eip+0x2b5>
		for (lline = lfun + 1;
f010468a:	83 c7 01             	add    $0x1,%edi
f010468d:	89 f8                	mov    %edi,%eax
f010468f:	8d 14 7f             	lea    (%edi,%edi,2),%edx
f0104692:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104695:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
f0104699:	eb 04                	jmp    f010469f <debuginfo_eip+0x26d>
			info->eip_fn_narg++;
f010469b:	83 46 14 01          	addl   $0x1,0x14(%esi)
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010469f:	39 c3                	cmp    %eax,%ebx
f01046a1:	7e 3f                	jle    f01046e2 <debuginfo_eip+0x2b0>
f01046a3:	0f b6 0a             	movzbl (%edx),%ecx
f01046a6:	83 c0 01             	add    $0x1,%eax
f01046a9:	83 c2 0c             	add    $0xc,%edx
f01046ac:	80 f9 a0             	cmp    $0xa0,%cl
f01046af:	74 ea                	je     f010469b <debuginfo_eip+0x269>
	return 0;
f01046b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01046b6:	eb 2f                	jmp    f01046e7 <debuginfo_eip+0x2b5>
			return -1;
f01046b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01046bd:	eb 28                	jmp    f01046e7 <debuginfo_eip+0x2b5>
			return -1;
f01046bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01046c4:	eb 21                	jmp    f01046e7 <debuginfo_eip+0x2b5>
		return -1;
f01046c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01046cb:	eb 1a                	jmp    f01046e7 <debuginfo_eip+0x2b5>
f01046cd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01046d2:	eb 13                	jmp    f01046e7 <debuginfo_eip+0x2b5>
		return -1;
f01046d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01046d9:	eb 0c                	jmp    f01046e7 <debuginfo_eip+0x2b5>
		return -1; 
f01046db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01046e0:	eb 05                	jmp    f01046e7 <debuginfo_eip+0x2b5>
	return 0;
f01046e2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01046e7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01046ea:	5b                   	pop    %ebx
f01046eb:	5e                   	pop    %esi
f01046ec:	5f                   	pop    %edi
f01046ed:	5d                   	pop    %ebp
f01046ee:	c3                   	ret    

f01046ef <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01046ef:	55                   	push   %ebp
f01046f0:	89 e5                	mov    %esp,%ebp
f01046f2:	57                   	push   %edi
f01046f3:	56                   	push   %esi
f01046f4:	53                   	push   %ebx
f01046f5:	83 ec 2c             	sub    $0x2c,%esp
f01046f8:	e8 72 ea ff ff       	call   f010316f <__x86.get_pc_thunk.cx>
f01046fd:	81 c1 2f b2 07 00    	add    $0x7b22f,%ecx
f0104703:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104706:	89 c7                	mov    %eax,%edi
f0104708:	89 d6                	mov    %edx,%esi
f010470a:	8b 45 08             	mov    0x8(%ebp),%eax
f010470d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104710:	89 d1                	mov    %edx,%ecx
f0104712:	89 c2                	mov    %eax,%edx
f0104714:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104717:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f010471a:	8b 45 10             	mov    0x10(%ebp),%eax
f010471d:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104720:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104723:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f010472a:	39 c2                	cmp    %eax,%edx
f010472c:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f010472f:	72 41                	jb     f0104772 <printnum+0x83>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104731:	83 ec 0c             	sub    $0xc,%esp
f0104734:	ff 75 18             	push   0x18(%ebp)
f0104737:	83 eb 01             	sub    $0x1,%ebx
f010473a:	53                   	push   %ebx
f010473b:	50                   	push   %eax
f010473c:	83 ec 08             	sub    $0x8,%esp
f010473f:	ff 75 e4             	push   -0x1c(%ebp)
f0104742:	ff 75 e0             	push   -0x20(%ebp)
f0104745:	ff 75 d4             	push   -0x2c(%ebp)
f0104748:	ff 75 d0             	push   -0x30(%ebp)
f010474b:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010474e:	e8 fd 09 00 00       	call   f0105150 <__udivdi3>
f0104753:	83 c4 18             	add    $0x18,%esp
f0104756:	52                   	push   %edx
f0104757:	50                   	push   %eax
f0104758:	89 f2                	mov    %esi,%edx
f010475a:	89 f8                	mov    %edi,%eax
f010475c:	e8 8e ff ff ff       	call   f01046ef <printnum>
f0104761:	83 c4 20             	add    $0x20,%esp
f0104764:	eb 13                	jmp    f0104779 <printnum+0x8a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104766:	83 ec 08             	sub    $0x8,%esp
f0104769:	56                   	push   %esi
f010476a:	ff 75 18             	push   0x18(%ebp)
f010476d:	ff d7                	call   *%edi
f010476f:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0104772:	83 eb 01             	sub    $0x1,%ebx
f0104775:	85 db                	test   %ebx,%ebx
f0104777:	7f ed                	jg     f0104766 <printnum+0x77>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104779:	83 ec 08             	sub    $0x8,%esp
f010477c:	56                   	push   %esi
f010477d:	83 ec 04             	sub    $0x4,%esp
f0104780:	ff 75 e4             	push   -0x1c(%ebp)
f0104783:	ff 75 e0             	push   -0x20(%ebp)
f0104786:	ff 75 d4             	push   -0x2c(%ebp)
f0104789:	ff 75 d0             	push   -0x30(%ebp)
f010478c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010478f:	e8 dc 0a 00 00       	call   f0105270 <__umoddi3>
f0104794:	83 c4 14             	add    $0x14,%esp
f0104797:	0f be 84 03 7a 6e f8 	movsbl -0x79186(%ebx,%eax,1),%eax
f010479e:	ff 
f010479f:	50                   	push   %eax
f01047a0:	ff d7                	call   *%edi
}
f01047a2:	83 c4 10             	add    $0x10,%esp
f01047a5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01047a8:	5b                   	pop    %ebx
f01047a9:	5e                   	pop    %esi
f01047aa:	5f                   	pop    %edi
f01047ab:	5d                   	pop    %ebp
f01047ac:	c3                   	ret    

f01047ad <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01047ad:	55                   	push   %ebp
f01047ae:	89 e5                	mov    %esp,%ebp
f01047b0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01047b3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01047b7:	8b 10                	mov    (%eax),%edx
f01047b9:	3b 50 04             	cmp    0x4(%eax),%edx
f01047bc:	73 0a                	jae    f01047c8 <sprintputch+0x1b>
		*b->buf++ = ch;
f01047be:	8d 4a 01             	lea    0x1(%edx),%ecx
f01047c1:	89 08                	mov    %ecx,(%eax)
f01047c3:	8b 45 08             	mov    0x8(%ebp),%eax
f01047c6:	88 02                	mov    %al,(%edx)
}
f01047c8:	5d                   	pop    %ebp
f01047c9:	c3                   	ret    

f01047ca <printfmt>:
{
f01047ca:	55                   	push   %ebp
f01047cb:	89 e5                	mov    %esp,%ebp
f01047cd:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f01047d0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01047d3:	50                   	push   %eax
f01047d4:	ff 75 10             	push   0x10(%ebp)
f01047d7:	ff 75 0c             	push   0xc(%ebp)
f01047da:	ff 75 08             	push   0x8(%ebp)
f01047dd:	e8 05 00 00 00       	call   f01047e7 <vprintfmt>
}
f01047e2:	83 c4 10             	add    $0x10,%esp
f01047e5:	c9                   	leave  
f01047e6:	c3                   	ret    

f01047e7 <vprintfmt>:
{
f01047e7:	55                   	push   %ebp
f01047e8:	89 e5                	mov    %esp,%ebp
f01047ea:	57                   	push   %edi
f01047eb:	56                   	push   %esi
f01047ec:	53                   	push   %ebx
f01047ed:	83 ec 3c             	sub    $0x3c,%esp
f01047f0:	e8 04 bf ff ff       	call   f01006f9 <__x86.get_pc_thunk.ax>
f01047f5:	05 37 b1 07 00       	add    $0x7b137,%eax
f01047fa:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01047fd:	8b 75 08             	mov    0x8(%ebp),%esi
f0104800:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104803:	8b 5d 10             	mov    0x10(%ebp),%ebx
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104806:	8d 80 84 17 00 00    	lea    0x1784(%eax),%eax
f010480c:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f010480f:	eb 0a                	jmp    f010481b <vprintfmt+0x34>
			putch(ch, putdat);
f0104811:	83 ec 08             	sub    $0x8,%esp
f0104814:	57                   	push   %edi
f0104815:	50                   	push   %eax
f0104816:	ff d6                	call   *%esi
f0104818:	83 c4 10             	add    $0x10,%esp
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010481b:	83 c3 01             	add    $0x1,%ebx
f010481e:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0104822:	83 f8 25             	cmp    $0x25,%eax
f0104825:	74 0c                	je     f0104833 <vprintfmt+0x4c>
			if (ch == '\0')
f0104827:	85 c0                	test   %eax,%eax
f0104829:	75 e6                	jne    f0104811 <vprintfmt+0x2a>
}
f010482b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010482e:	5b                   	pop    %ebx
f010482f:	5e                   	pop    %esi
f0104830:	5f                   	pop    %edi
f0104831:	5d                   	pop    %ebp
f0104832:	c3                   	ret    
		padc = ' ';
f0104833:	c6 45 cf 20          	movb   $0x20,-0x31(%ebp)
		altflag = 0;
f0104837:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
		precision = -1;
f010483e:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		width = -1;
f0104845:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		lflag = 0;
f010484c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104851:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0104854:	89 75 08             	mov    %esi,0x8(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104857:	8d 43 01             	lea    0x1(%ebx),%eax
f010485a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010485d:	0f b6 13             	movzbl (%ebx),%edx
f0104860:	8d 42 dd             	lea    -0x23(%edx),%eax
f0104863:	3c 55                	cmp    $0x55,%al
f0104865:	0f 87 c5 03 00 00    	ja     f0104c30 <.L20>
f010486b:	0f b6 c0             	movzbl %al,%eax
f010486e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104871:	89 ce                	mov    %ecx,%esi
f0104873:	03 b4 81 04 6f f8 ff 	add    -0x790fc(%ecx,%eax,4),%esi
f010487a:	ff e6                	jmp    *%esi

f010487c <.L66>:
f010487c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '-';
f010487f:	c6 45 cf 2d          	movb   $0x2d,-0x31(%ebp)
f0104883:	eb d2                	jmp    f0104857 <vprintfmt+0x70>

f0104885 <.L32>:
		switch (ch = *(unsigned char *) fmt++) {
f0104885:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104888:	c6 45 cf 30          	movb   $0x30,-0x31(%ebp)
f010488c:	eb c9                	jmp    f0104857 <vprintfmt+0x70>

f010488e <.L31>:
f010488e:	0f b6 d2             	movzbl %dl,%edx
f0104891:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			for (precision = 0; ; ++fmt) {
f0104894:	b8 00 00 00 00       	mov    $0x0,%eax
f0104899:	8b 75 08             	mov    0x8(%ebp),%esi
				precision = precision * 10 + ch - '0';
f010489c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010489f:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f01048a3:	0f be 13             	movsbl (%ebx),%edx
				if (ch < '0' || ch > '9')
f01048a6:	8d 4a d0             	lea    -0x30(%edx),%ecx
f01048a9:	83 f9 09             	cmp    $0x9,%ecx
f01048ac:	77 58                	ja     f0104906 <.L36+0xf>
			for (precision = 0; ; ++fmt) {
f01048ae:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
f01048b1:	eb e9                	jmp    f010489c <.L31+0xe>

f01048b3 <.L34>:
			precision = va_arg(ap, int);
f01048b3:	8b 45 14             	mov    0x14(%ebp),%eax
f01048b6:	8b 00                	mov    (%eax),%eax
f01048b8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01048bb:	8b 45 14             	mov    0x14(%ebp),%eax
f01048be:	8d 40 04             	lea    0x4(%eax),%eax
f01048c1:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01048c4:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if (width < 0)
f01048c7:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01048cb:	79 8a                	jns    f0104857 <vprintfmt+0x70>
				width = precision, precision = -1;
f01048cd:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01048d0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01048d3:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f01048da:	e9 78 ff ff ff       	jmp    f0104857 <vprintfmt+0x70>

f01048df <.L33>:
f01048df:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01048e2:	85 d2                	test   %edx,%edx
f01048e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01048e9:	0f 49 c2             	cmovns %edx,%eax
f01048ec:	89 45 d0             	mov    %eax,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01048ef:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f01048f2:	e9 60 ff ff ff       	jmp    f0104857 <vprintfmt+0x70>

f01048f7 <.L36>:
		switch (ch = *(unsigned char *) fmt++) {
f01048f7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			altflag = 1;
f01048fa:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
			goto reswitch;
f0104901:	e9 51 ff ff ff       	jmp    f0104857 <vprintfmt+0x70>
f0104906:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104909:	89 75 08             	mov    %esi,0x8(%ebp)
f010490c:	eb b9                	jmp    f01048c7 <.L34+0x14>

f010490e <.L27>:
			lflag++;
f010490e:	83 45 c8 01          	addl   $0x1,-0x38(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104912:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f0104915:	e9 3d ff ff ff       	jmp    f0104857 <vprintfmt+0x70>

f010491a <.L30>:
			putch(va_arg(ap, int), putdat);
f010491a:	8b 75 08             	mov    0x8(%ebp),%esi
f010491d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104920:	8d 58 04             	lea    0x4(%eax),%ebx
f0104923:	83 ec 08             	sub    $0x8,%esp
f0104926:	57                   	push   %edi
f0104927:	ff 30                	push   (%eax)
f0104929:	ff d6                	call   *%esi
			break;
f010492b:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f010492e:	89 5d 14             	mov    %ebx,0x14(%ebp)
			break;
f0104931:	e9 90 02 00 00       	jmp    f0104bc6 <.L25+0x45>

f0104936 <.L28>:
			err = va_arg(ap, int);
f0104936:	8b 75 08             	mov    0x8(%ebp),%esi
f0104939:	8b 45 14             	mov    0x14(%ebp),%eax
f010493c:	8d 58 04             	lea    0x4(%eax),%ebx
f010493f:	8b 10                	mov    (%eax),%edx
f0104941:	89 d0                	mov    %edx,%eax
f0104943:	f7 d8                	neg    %eax
f0104945:	0f 48 c2             	cmovs  %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104948:	83 f8 06             	cmp    $0x6,%eax
f010494b:	7f 27                	jg     f0104974 <.L28+0x3e>
f010494d:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0104950:	8b 14 82             	mov    (%edx,%eax,4),%edx
f0104953:	85 d2                	test   %edx,%edx
f0104955:	74 1d                	je     f0104974 <.L28+0x3e>
				printfmt(putch, putdat, "%s", p);
f0104957:	52                   	push   %edx
f0104958:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010495b:	8d 80 81 5f f8 ff    	lea    -0x7a07f(%eax),%eax
f0104961:	50                   	push   %eax
f0104962:	57                   	push   %edi
f0104963:	56                   	push   %esi
f0104964:	e8 61 fe ff ff       	call   f01047ca <printfmt>
f0104969:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010496c:	89 5d 14             	mov    %ebx,0x14(%ebp)
f010496f:	e9 52 02 00 00       	jmp    f0104bc6 <.L25+0x45>
				printfmt(putch, putdat, "error %d", err);
f0104974:	50                   	push   %eax
f0104975:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104978:	8d 80 92 6e f8 ff    	lea    -0x7916e(%eax),%eax
f010497e:	50                   	push   %eax
f010497f:	57                   	push   %edi
f0104980:	56                   	push   %esi
f0104981:	e8 44 fe ff ff       	call   f01047ca <printfmt>
f0104986:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0104989:	89 5d 14             	mov    %ebx,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f010498c:	e9 35 02 00 00       	jmp    f0104bc6 <.L25+0x45>

f0104991 <.L24>:
			if ((p = va_arg(ap, char *)) == NULL)
f0104991:	8b 75 08             	mov    0x8(%ebp),%esi
f0104994:	8b 45 14             	mov    0x14(%ebp),%eax
f0104997:	83 c0 04             	add    $0x4,%eax
f010499a:	89 45 c0             	mov    %eax,-0x40(%ebp)
f010499d:	8b 45 14             	mov    0x14(%ebp),%eax
f01049a0:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f01049a2:	85 d2                	test   %edx,%edx
f01049a4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01049a7:	8d 80 8b 6e f8 ff    	lea    -0x79175(%eax),%eax
f01049ad:	0f 45 c2             	cmovne %edx,%eax
f01049b0:	89 45 c8             	mov    %eax,-0x38(%ebp)
			if (width > 0 && padc != '-')
f01049b3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01049b7:	7e 06                	jle    f01049bf <.L24+0x2e>
f01049b9:	80 7d cf 2d          	cmpb   $0x2d,-0x31(%ebp)
f01049bd:	75 0d                	jne    f01049cc <.L24+0x3b>
				for (width -= strnlen(p, precision); width > 0; width--)
f01049bf:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01049c2:	89 c3                	mov    %eax,%ebx
f01049c4:	03 45 d0             	add    -0x30(%ebp),%eax
f01049c7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01049ca:	eb 58                	jmp    f0104a24 <.L24+0x93>
f01049cc:	83 ec 08             	sub    $0x8,%esp
f01049cf:	ff 75 d8             	push   -0x28(%ebp)
f01049d2:	ff 75 c8             	push   -0x38(%ebp)
f01049d5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01049d8:	e8 0c 04 00 00       	call   f0104de9 <strnlen>
f01049dd:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01049e0:	29 c2                	sub    %eax,%edx
f01049e2:	89 55 bc             	mov    %edx,-0x44(%ebp)
f01049e5:	83 c4 10             	add    $0x10,%esp
f01049e8:	89 d3                	mov    %edx,%ebx
					putch(padc, putdat);
f01049ea:	0f be 45 cf          	movsbl -0x31(%ebp),%eax
f01049ee:	89 45 d0             	mov    %eax,-0x30(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f01049f1:	eb 0f                	jmp    f0104a02 <.L24+0x71>
					putch(padc, putdat);
f01049f3:	83 ec 08             	sub    $0x8,%esp
f01049f6:	57                   	push   %edi
f01049f7:	ff 75 d0             	push   -0x30(%ebp)
f01049fa:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f01049fc:	83 eb 01             	sub    $0x1,%ebx
f01049ff:	83 c4 10             	add    $0x10,%esp
f0104a02:	85 db                	test   %ebx,%ebx
f0104a04:	7f ed                	jg     f01049f3 <.L24+0x62>
f0104a06:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104a09:	85 d2                	test   %edx,%edx
f0104a0b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a10:	0f 49 c2             	cmovns %edx,%eax
f0104a13:	29 c2                	sub    %eax,%edx
f0104a15:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0104a18:	eb a5                	jmp    f01049bf <.L24+0x2e>
					putch(ch, putdat);
f0104a1a:	83 ec 08             	sub    $0x8,%esp
f0104a1d:	57                   	push   %edi
f0104a1e:	52                   	push   %edx
f0104a1f:	ff d6                	call   *%esi
f0104a21:	83 c4 10             	add    $0x10,%esp
f0104a24:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0104a27:	29 d9                	sub    %ebx,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104a29:	83 c3 01             	add    $0x1,%ebx
f0104a2c:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0104a30:	0f be d0             	movsbl %al,%edx
f0104a33:	85 d2                	test   %edx,%edx
f0104a35:	74 4b                	je     f0104a82 <.L24+0xf1>
f0104a37:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104a3b:	78 06                	js     f0104a43 <.L24+0xb2>
f0104a3d:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f0104a41:	78 1e                	js     f0104a61 <.L24+0xd0>
				if (altflag && (ch < ' ' || ch > '~'))
f0104a43:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0104a47:	74 d1                	je     f0104a1a <.L24+0x89>
f0104a49:	0f be c0             	movsbl %al,%eax
f0104a4c:	83 e8 20             	sub    $0x20,%eax
f0104a4f:	83 f8 5e             	cmp    $0x5e,%eax
f0104a52:	76 c6                	jbe    f0104a1a <.L24+0x89>
					putch('?', putdat);
f0104a54:	83 ec 08             	sub    $0x8,%esp
f0104a57:	57                   	push   %edi
f0104a58:	6a 3f                	push   $0x3f
f0104a5a:	ff d6                	call   *%esi
f0104a5c:	83 c4 10             	add    $0x10,%esp
f0104a5f:	eb c3                	jmp    f0104a24 <.L24+0x93>
f0104a61:	89 cb                	mov    %ecx,%ebx
f0104a63:	eb 0e                	jmp    f0104a73 <.L24+0xe2>
				putch(' ', putdat);
f0104a65:	83 ec 08             	sub    $0x8,%esp
f0104a68:	57                   	push   %edi
f0104a69:	6a 20                	push   $0x20
f0104a6b:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0104a6d:	83 eb 01             	sub    $0x1,%ebx
f0104a70:	83 c4 10             	add    $0x10,%esp
f0104a73:	85 db                	test   %ebx,%ebx
f0104a75:	7f ee                	jg     f0104a65 <.L24+0xd4>
			if ((p = va_arg(ap, char *)) == NULL)
f0104a77:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0104a7a:	89 45 14             	mov    %eax,0x14(%ebp)
f0104a7d:	e9 44 01 00 00       	jmp    f0104bc6 <.L25+0x45>
f0104a82:	89 cb                	mov    %ecx,%ebx
f0104a84:	eb ed                	jmp    f0104a73 <.L24+0xe2>

f0104a86 <.L29>:
	if (lflag >= 2)
f0104a86:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0104a89:	8b 75 08             	mov    0x8(%ebp),%esi
f0104a8c:	83 f9 01             	cmp    $0x1,%ecx
f0104a8f:	7f 1b                	jg     f0104aac <.L29+0x26>
	else if (lflag)
f0104a91:	85 c9                	test   %ecx,%ecx
f0104a93:	74 63                	je     f0104af8 <.L29+0x72>
		return va_arg(*ap, long);
f0104a95:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a98:	8b 00                	mov    (%eax),%eax
f0104a9a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104a9d:	99                   	cltd   
f0104a9e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104aa1:	8b 45 14             	mov    0x14(%ebp),%eax
f0104aa4:	8d 40 04             	lea    0x4(%eax),%eax
f0104aa7:	89 45 14             	mov    %eax,0x14(%ebp)
f0104aaa:	eb 17                	jmp    f0104ac3 <.L29+0x3d>
		return va_arg(*ap, long long);
f0104aac:	8b 45 14             	mov    0x14(%ebp),%eax
f0104aaf:	8b 50 04             	mov    0x4(%eax),%edx
f0104ab2:	8b 00                	mov    (%eax),%eax
f0104ab4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104ab7:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104aba:	8b 45 14             	mov    0x14(%ebp),%eax
f0104abd:	8d 40 08             	lea    0x8(%eax),%eax
f0104ac0:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0104ac3:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0104ac6:	8b 5d dc             	mov    -0x24(%ebp),%ebx
			base = 10;
f0104ac9:	ba 0a 00 00 00       	mov    $0xa,%edx
			if ((long long) num < 0) {
f0104ace:	85 db                	test   %ebx,%ebx
f0104ad0:	0f 89 d6 00 00 00    	jns    f0104bac <.L25+0x2b>
				putch('-', putdat);
f0104ad6:	83 ec 08             	sub    $0x8,%esp
f0104ad9:	57                   	push   %edi
f0104ada:	6a 2d                	push   $0x2d
f0104adc:	ff d6                	call   *%esi
				num = -(long long) num;
f0104ade:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0104ae1:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104ae4:	f7 d9                	neg    %ecx
f0104ae6:	83 d3 00             	adc    $0x0,%ebx
f0104ae9:	f7 db                	neg    %ebx
f0104aeb:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0104aee:	ba 0a 00 00 00       	mov    $0xa,%edx
f0104af3:	e9 b4 00 00 00       	jmp    f0104bac <.L25+0x2b>
		return va_arg(*ap, int);
f0104af8:	8b 45 14             	mov    0x14(%ebp),%eax
f0104afb:	8b 00                	mov    (%eax),%eax
f0104afd:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104b00:	99                   	cltd   
f0104b01:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104b04:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b07:	8d 40 04             	lea    0x4(%eax),%eax
f0104b0a:	89 45 14             	mov    %eax,0x14(%ebp)
f0104b0d:	eb b4                	jmp    f0104ac3 <.L29+0x3d>

f0104b0f <.L23>:
	if (lflag >= 2)
f0104b0f:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0104b12:	8b 75 08             	mov    0x8(%ebp),%esi
f0104b15:	83 f9 01             	cmp    $0x1,%ecx
f0104b18:	7f 1b                	jg     f0104b35 <.L23+0x26>
	else if (lflag)
f0104b1a:	85 c9                	test   %ecx,%ecx
f0104b1c:	74 2c                	je     f0104b4a <.L23+0x3b>
		return va_arg(*ap, unsigned long);
f0104b1e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b21:	8b 08                	mov    (%eax),%ecx
f0104b23:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104b28:	8d 40 04             	lea    0x4(%eax),%eax
f0104b2b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104b2e:	ba 0a 00 00 00       	mov    $0xa,%edx
		return va_arg(*ap, unsigned long);
f0104b33:	eb 77                	jmp    f0104bac <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f0104b35:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b38:	8b 08                	mov    (%eax),%ecx
f0104b3a:	8b 58 04             	mov    0x4(%eax),%ebx
f0104b3d:	8d 40 08             	lea    0x8(%eax),%eax
f0104b40:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104b43:	ba 0a 00 00 00       	mov    $0xa,%edx
		return va_arg(*ap, unsigned long long);
f0104b48:	eb 62                	jmp    f0104bac <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f0104b4a:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b4d:	8b 08                	mov    (%eax),%ecx
f0104b4f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104b54:	8d 40 04             	lea    0x4(%eax),%eax
f0104b57:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104b5a:	ba 0a 00 00 00       	mov    $0xa,%edx
		return va_arg(*ap, unsigned int);
f0104b5f:	eb 4b                	jmp    f0104bac <.L25+0x2b>

f0104b61 <.L26>:
			putch('X', putdat);
f0104b61:	8b 75 08             	mov    0x8(%ebp),%esi
f0104b64:	83 ec 08             	sub    $0x8,%esp
f0104b67:	57                   	push   %edi
f0104b68:	6a 58                	push   $0x58
f0104b6a:	ff d6                	call   *%esi
			putch('X', putdat);
f0104b6c:	83 c4 08             	add    $0x8,%esp
f0104b6f:	57                   	push   %edi
f0104b70:	6a 58                	push   $0x58
f0104b72:	ff d6                	call   *%esi
			putch('X', putdat);
f0104b74:	83 c4 08             	add    $0x8,%esp
f0104b77:	57                   	push   %edi
f0104b78:	6a 58                	push   $0x58
f0104b7a:	ff d6                	call   *%esi
			break;
f0104b7c:	83 c4 10             	add    $0x10,%esp
f0104b7f:	eb 45                	jmp    f0104bc6 <.L25+0x45>

f0104b81 <.L25>:
			putch('0', putdat);
f0104b81:	8b 75 08             	mov    0x8(%ebp),%esi
f0104b84:	83 ec 08             	sub    $0x8,%esp
f0104b87:	57                   	push   %edi
f0104b88:	6a 30                	push   $0x30
f0104b8a:	ff d6                	call   *%esi
			putch('x', putdat);
f0104b8c:	83 c4 08             	add    $0x8,%esp
f0104b8f:	57                   	push   %edi
f0104b90:	6a 78                	push   $0x78
f0104b92:	ff d6                	call   *%esi
			num = (unsigned long long)
f0104b94:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b97:	8b 08                	mov    (%eax),%ecx
f0104b99:	bb 00 00 00 00       	mov    $0x0,%ebx
			goto number;
f0104b9e:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0104ba1:	8d 40 04             	lea    0x4(%eax),%eax
f0104ba4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104ba7:	ba 10 00 00 00       	mov    $0x10,%edx
			printnum(putch, putdat, num, base, width, padc);
f0104bac:	83 ec 0c             	sub    $0xc,%esp
f0104baf:	0f be 45 cf          	movsbl -0x31(%ebp),%eax
f0104bb3:	50                   	push   %eax
f0104bb4:	ff 75 d0             	push   -0x30(%ebp)
f0104bb7:	52                   	push   %edx
f0104bb8:	53                   	push   %ebx
f0104bb9:	51                   	push   %ecx
f0104bba:	89 fa                	mov    %edi,%edx
f0104bbc:	89 f0                	mov    %esi,%eax
f0104bbe:	e8 2c fb ff ff       	call   f01046ef <printnum>
			break;
f0104bc3:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0104bc6:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104bc9:	e9 4d fc ff ff       	jmp    f010481b <vprintfmt+0x34>

f0104bce <.L21>:
	if (lflag >= 2)
f0104bce:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0104bd1:	8b 75 08             	mov    0x8(%ebp),%esi
f0104bd4:	83 f9 01             	cmp    $0x1,%ecx
f0104bd7:	7f 1b                	jg     f0104bf4 <.L21+0x26>
	else if (lflag)
f0104bd9:	85 c9                	test   %ecx,%ecx
f0104bdb:	74 2c                	je     f0104c09 <.L21+0x3b>
		return va_arg(*ap, unsigned long);
f0104bdd:	8b 45 14             	mov    0x14(%ebp),%eax
f0104be0:	8b 08                	mov    (%eax),%ecx
f0104be2:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104be7:	8d 40 04             	lea    0x4(%eax),%eax
f0104bea:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104bed:	ba 10 00 00 00       	mov    $0x10,%edx
		return va_arg(*ap, unsigned long);
f0104bf2:	eb b8                	jmp    f0104bac <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f0104bf4:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bf7:	8b 08                	mov    (%eax),%ecx
f0104bf9:	8b 58 04             	mov    0x4(%eax),%ebx
f0104bfc:	8d 40 08             	lea    0x8(%eax),%eax
f0104bff:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104c02:	ba 10 00 00 00       	mov    $0x10,%edx
		return va_arg(*ap, unsigned long long);
f0104c07:	eb a3                	jmp    f0104bac <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f0104c09:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c0c:	8b 08                	mov    (%eax),%ecx
f0104c0e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104c13:	8d 40 04             	lea    0x4(%eax),%eax
f0104c16:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104c19:	ba 10 00 00 00       	mov    $0x10,%edx
		return va_arg(*ap, unsigned int);
f0104c1e:	eb 8c                	jmp    f0104bac <.L25+0x2b>

f0104c20 <.L35>:
			putch(ch, putdat);
f0104c20:	8b 75 08             	mov    0x8(%ebp),%esi
f0104c23:	83 ec 08             	sub    $0x8,%esp
f0104c26:	57                   	push   %edi
f0104c27:	6a 25                	push   $0x25
f0104c29:	ff d6                	call   *%esi
			break;
f0104c2b:	83 c4 10             	add    $0x10,%esp
f0104c2e:	eb 96                	jmp    f0104bc6 <.L25+0x45>

f0104c30 <.L20>:
			putch('%', putdat);
f0104c30:	8b 75 08             	mov    0x8(%ebp),%esi
f0104c33:	83 ec 08             	sub    $0x8,%esp
f0104c36:	57                   	push   %edi
f0104c37:	6a 25                	push   $0x25
f0104c39:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104c3b:	83 c4 10             	add    $0x10,%esp
f0104c3e:	89 d8                	mov    %ebx,%eax
f0104c40:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0104c44:	74 05                	je     f0104c4b <.L20+0x1b>
f0104c46:	83 e8 01             	sub    $0x1,%eax
f0104c49:	eb f5                	jmp    f0104c40 <.L20+0x10>
f0104c4b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104c4e:	e9 73 ff ff ff       	jmp    f0104bc6 <.L25+0x45>

f0104c53 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104c53:	55                   	push   %ebp
f0104c54:	89 e5                	mov    %esp,%ebp
f0104c56:	53                   	push   %ebx
f0104c57:	83 ec 14             	sub    $0x14,%esp
f0104c5a:	e8 08 b5 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104c5f:	81 c3 cd ac 07 00    	add    $0x7accd,%ebx
f0104c65:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c68:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104c6b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104c6e:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104c72:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104c75:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104c7c:	85 c0                	test   %eax,%eax
f0104c7e:	74 2b                	je     f0104cab <vsnprintf+0x58>
f0104c80:	85 d2                	test   %edx,%edx
f0104c82:	7e 27                	jle    f0104cab <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104c84:	ff 75 14             	push   0x14(%ebp)
f0104c87:	ff 75 10             	push   0x10(%ebp)
f0104c8a:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104c8d:	50                   	push   %eax
f0104c8e:	8d 83 81 4e f8 ff    	lea    -0x7b17f(%ebx),%eax
f0104c94:	50                   	push   %eax
f0104c95:	e8 4d fb ff ff       	call   f01047e7 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104c9a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104c9d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104ca0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104ca3:	83 c4 10             	add    $0x10,%esp
}
f0104ca6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104ca9:	c9                   	leave  
f0104caa:	c3                   	ret    
		return -E_INVAL;
f0104cab:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104cb0:	eb f4                	jmp    f0104ca6 <vsnprintf+0x53>

f0104cb2 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104cb2:	55                   	push   %ebp
f0104cb3:	89 e5                	mov    %esp,%ebp
f0104cb5:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104cb8:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104cbb:	50                   	push   %eax
f0104cbc:	ff 75 10             	push   0x10(%ebp)
f0104cbf:	ff 75 0c             	push   0xc(%ebp)
f0104cc2:	ff 75 08             	push   0x8(%ebp)
f0104cc5:	e8 89 ff ff ff       	call   f0104c53 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104cca:	c9                   	leave  
f0104ccb:	c3                   	ret    

f0104ccc <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104ccc:	55                   	push   %ebp
f0104ccd:	89 e5                	mov    %esp,%ebp
f0104ccf:	57                   	push   %edi
f0104cd0:	56                   	push   %esi
f0104cd1:	53                   	push   %ebx
f0104cd2:	83 ec 1c             	sub    $0x1c,%esp
f0104cd5:	e8 8d b4 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104cda:	81 c3 52 ac 07 00    	add    $0x7ac52,%ebx
f0104ce0:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104ce3:	85 c0                	test   %eax,%eax
f0104ce5:	74 13                	je     f0104cfa <readline+0x2e>
		cprintf("%s", prompt);
f0104ce7:	83 ec 08             	sub    $0x8,%esp
f0104cea:	50                   	push   %eax
f0104ceb:	8d 83 81 5f f8 ff    	lea    -0x7a07f(%ebx),%eax
f0104cf1:	50                   	push   %eax
f0104cf2:	e8 1e ec ff ff       	call   f0103915 <cprintf>
f0104cf7:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104cfa:	83 ec 0c             	sub    $0xc,%esp
f0104cfd:	6a 00                	push   $0x0
f0104cff:	e8 ef b9 ff ff       	call   f01006f3 <iscons>
f0104d04:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104d07:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0104d0a:	bf 00 00 00 00       	mov    $0x0,%edi
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
			if (echoing)
				cputchar(c);
			buf[i++] = c;
f0104d0f:	8d 83 d4 22 00 00    	lea    0x22d4(%ebx),%eax
f0104d15:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104d18:	eb 45                	jmp    f0104d5f <readline+0x93>
			cprintf("read error: %e\n", c);
f0104d1a:	83 ec 08             	sub    $0x8,%esp
f0104d1d:	50                   	push   %eax
f0104d1e:	8d 83 5c 70 f8 ff    	lea    -0x78fa4(%ebx),%eax
f0104d24:	50                   	push   %eax
f0104d25:	e8 eb eb ff ff       	call   f0103915 <cprintf>
			return NULL;
f0104d2a:	83 c4 10             	add    $0x10,%esp
f0104d2d:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0104d32:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104d35:	5b                   	pop    %ebx
f0104d36:	5e                   	pop    %esi
f0104d37:	5f                   	pop    %edi
f0104d38:	5d                   	pop    %ebp
f0104d39:	c3                   	ret    
			if (echoing)
f0104d3a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104d3e:	75 05                	jne    f0104d45 <readline+0x79>
			i--;
f0104d40:	83 ef 01             	sub    $0x1,%edi
f0104d43:	eb 1a                	jmp    f0104d5f <readline+0x93>
				cputchar('\b');
f0104d45:	83 ec 0c             	sub    $0xc,%esp
f0104d48:	6a 08                	push   $0x8
f0104d4a:	e8 83 b9 ff ff       	call   f01006d2 <cputchar>
f0104d4f:	83 c4 10             	add    $0x10,%esp
f0104d52:	eb ec                	jmp    f0104d40 <readline+0x74>
			buf[i++] = c;
f0104d54:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104d57:	89 f0                	mov    %esi,%eax
f0104d59:	88 04 39             	mov    %al,(%ecx,%edi,1)
f0104d5c:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0104d5f:	e8 7e b9 ff ff       	call   f01006e2 <getchar>
f0104d64:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0104d66:	85 c0                	test   %eax,%eax
f0104d68:	78 b0                	js     f0104d1a <readline+0x4e>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104d6a:	83 f8 08             	cmp    $0x8,%eax
f0104d6d:	0f 94 c0             	sete   %al
f0104d70:	83 fe 7f             	cmp    $0x7f,%esi
f0104d73:	0f 94 c2             	sete   %dl
f0104d76:	08 d0                	or     %dl,%al
f0104d78:	74 04                	je     f0104d7e <readline+0xb2>
f0104d7a:	85 ff                	test   %edi,%edi
f0104d7c:	7f bc                	jg     f0104d3a <readline+0x6e>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104d7e:	83 fe 1f             	cmp    $0x1f,%esi
f0104d81:	7e 1c                	jle    f0104d9f <readline+0xd3>
f0104d83:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0104d89:	7f 14                	jg     f0104d9f <readline+0xd3>
			if (echoing)
f0104d8b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104d8f:	74 c3                	je     f0104d54 <readline+0x88>
				cputchar(c);
f0104d91:	83 ec 0c             	sub    $0xc,%esp
f0104d94:	56                   	push   %esi
f0104d95:	e8 38 b9 ff ff       	call   f01006d2 <cputchar>
f0104d9a:	83 c4 10             	add    $0x10,%esp
f0104d9d:	eb b5                	jmp    f0104d54 <readline+0x88>
		} else if (c == '\n' || c == '\r') {
f0104d9f:	83 fe 0a             	cmp    $0xa,%esi
f0104da2:	74 05                	je     f0104da9 <readline+0xdd>
f0104da4:	83 fe 0d             	cmp    $0xd,%esi
f0104da7:	75 b6                	jne    f0104d5f <readline+0x93>
			if (echoing)
f0104da9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104dad:	75 13                	jne    f0104dc2 <readline+0xf6>
			buf[i] = 0;
f0104daf:	c6 84 3b d4 22 00 00 	movb   $0x0,0x22d4(%ebx,%edi,1)
f0104db6:	00 
			return buf;
f0104db7:	8d 83 d4 22 00 00    	lea    0x22d4(%ebx),%eax
f0104dbd:	e9 70 ff ff ff       	jmp    f0104d32 <readline+0x66>
				cputchar('\n');
f0104dc2:	83 ec 0c             	sub    $0xc,%esp
f0104dc5:	6a 0a                	push   $0xa
f0104dc7:	e8 06 b9 ff ff       	call   f01006d2 <cputchar>
f0104dcc:	83 c4 10             	add    $0x10,%esp
f0104dcf:	eb de                	jmp    f0104daf <readline+0xe3>

f0104dd1 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104dd1:	55                   	push   %ebp
f0104dd2:	89 e5                	mov    %esp,%ebp
f0104dd4:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104dd7:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ddc:	eb 03                	jmp    f0104de1 <strlen+0x10>
		n++;
f0104dde:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0104de1:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104de5:	75 f7                	jne    f0104dde <strlen+0xd>
	return n;
}
f0104de7:	5d                   	pop    %ebp
f0104de8:	c3                   	ret    

f0104de9 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104de9:	55                   	push   %ebp
f0104dea:	89 e5                	mov    %esp,%ebp
f0104dec:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104def:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104df2:	b8 00 00 00 00       	mov    $0x0,%eax
f0104df7:	eb 03                	jmp    f0104dfc <strnlen+0x13>
		n++;
f0104df9:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104dfc:	39 d0                	cmp    %edx,%eax
f0104dfe:	74 08                	je     f0104e08 <strnlen+0x1f>
f0104e00:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104e04:	75 f3                	jne    f0104df9 <strnlen+0x10>
f0104e06:	89 c2                	mov    %eax,%edx
	return n;
}
f0104e08:	89 d0                	mov    %edx,%eax
f0104e0a:	5d                   	pop    %ebp
f0104e0b:	c3                   	ret    

f0104e0c <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104e0c:	55                   	push   %ebp
f0104e0d:	89 e5                	mov    %esp,%ebp
f0104e0f:	53                   	push   %ebx
f0104e10:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104e13:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104e16:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e1b:	0f b6 14 03          	movzbl (%ebx,%eax,1),%edx
f0104e1f:	88 14 01             	mov    %dl,(%ecx,%eax,1)
f0104e22:	83 c0 01             	add    $0x1,%eax
f0104e25:	84 d2                	test   %dl,%dl
f0104e27:	75 f2                	jne    f0104e1b <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0104e29:	89 c8                	mov    %ecx,%eax
f0104e2b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104e2e:	c9                   	leave  
f0104e2f:	c3                   	ret    

f0104e30 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104e30:	55                   	push   %ebp
f0104e31:	89 e5                	mov    %esp,%ebp
f0104e33:	53                   	push   %ebx
f0104e34:	83 ec 10             	sub    $0x10,%esp
f0104e37:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104e3a:	53                   	push   %ebx
f0104e3b:	e8 91 ff ff ff       	call   f0104dd1 <strlen>
f0104e40:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f0104e43:	ff 75 0c             	push   0xc(%ebp)
f0104e46:	01 d8                	add    %ebx,%eax
f0104e48:	50                   	push   %eax
f0104e49:	e8 be ff ff ff       	call   f0104e0c <strcpy>
	return dst;
}
f0104e4e:	89 d8                	mov    %ebx,%eax
f0104e50:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104e53:	c9                   	leave  
f0104e54:	c3                   	ret    

f0104e55 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104e55:	55                   	push   %ebp
f0104e56:	89 e5                	mov    %esp,%ebp
f0104e58:	56                   	push   %esi
f0104e59:	53                   	push   %ebx
f0104e5a:	8b 75 08             	mov    0x8(%ebp),%esi
f0104e5d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104e60:	89 f3                	mov    %esi,%ebx
f0104e62:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104e65:	89 f0                	mov    %esi,%eax
f0104e67:	eb 0f                	jmp    f0104e78 <strncpy+0x23>
		*dst++ = *src;
f0104e69:	83 c0 01             	add    $0x1,%eax
f0104e6c:	0f b6 0a             	movzbl (%edx),%ecx
f0104e6f:	88 48 ff             	mov    %cl,-0x1(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104e72:	80 f9 01             	cmp    $0x1,%cl
f0104e75:	83 da ff             	sbb    $0xffffffff,%edx
	for (i = 0; i < size; i++) {
f0104e78:	39 d8                	cmp    %ebx,%eax
f0104e7a:	75 ed                	jne    f0104e69 <strncpy+0x14>
	}
	return ret;
}
f0104e7c:	89 f0                	mov    %esi,%eax
f0104e7e:	5b                   	pop    %ebx
f0104e7f:	5e                   	pop    %esi
f0104e80:	5d                   	pop    %ebp
f0104e81:	c3                   	ret    

f0104e82 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104e82:	55                   	push   %ebp
f0104e83:	89 e5                	mov    %esp,%ebp
f0104e85:	56                   	push   %esi
f0104e86:	53                   	push   %ebx
f0104e87:	8b 75 08             	mov    0x8(%ebp),%esi
f0104e8a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104e8d:	8b 55 10             	mov    0x10(%ebp),%edx
f0104e90:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104e92:	85 d2                	test   %edx,%edx
f0104e94:	74 21                	je     f0104eb7 <strlcpy+0x35>
f0104e96:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104e9a:	89 f2                	mov    %esi,%edx
f0104e9c:	eb 09                	jmp    f0104ea7 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104e9e:	83 c1 01             	add    $0x1,%ecx
f0104ea1:	83 c2 01             	add    $0x1,%edx
f0104ea4:	88 5a ff             	mov    %bl,-0x1(%edx)
		while (--size > 0 && *src != '\0')
f0104ea7:	39 c2                	cmp    %eax,%edx
f0104ea9:	74 09                	je     f0104eb4 <strlcpy+0x32>
f0104eab:	0f b6 19             	movzbl (%ecx),%ebx
f0104eae:	84 db                	test   %bl,%bl
f0104eb0:	75 ec                	jne    f0104e9e <strlcpy+0x1c>
f0104eb2:	89 d0                	mov    %edx,%eax
		*dst = '\0';
f0104eb4:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104eb7:	29 f0                	sub    %esi,%eax
}
f0104eb9:	5b                   	pop    %ebx
f0104eba:	5e                   	pop    %esi
f0104ebb:	5d                   	pop    %ebp
f0104ebc:	c3                   	ret    

f0104ebd <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104ebd:	55                   	push   %ebp
f0104ebe:	89 e5                	mov    %esp,%ebp
f0104ec0:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104ec3:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104ec6:	eb 06                	jmp    f0104ece <strcmp+0x11>
		p++, q++;
f0104ec8:	83 c1 01             	add    $0x1,%ecx
f0104ecb:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0104ece:	0f b6 01             	movzbl (%ecx),%eax
f0104ed1:	84 c0                	test   %al,%al
f0104ed3:	74 04                	je     f0104ed9 <strcmp+0x1c>
f0104ed5:	3a 02                	cmp    (%edx),%al
f0104ed7:	74 ef                	je     f0104ec8 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104ed9:	0f b6 c0             	movzbl %al,%eax
f0104edc:	0f b6 12             	movzbl (%edx),%edx
f0104edf:	29 d0                	sub    %edx,%eax
}
f0104ee1:	5d                   	pop    %ebp
f0104ee2:	c3                   	ret    

f0104ee3 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104ee3:	55                   	push   %ebp
f0104ee4:	89 e5                	mov    %esp,%ebp
f0104ee6:	53                   	push   %ebx
f0104ee7:	8b 45 08             	mov    0x8(%ebp),%eax
f0104eea:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104eed:	89 c3                	mov    %eax,%ebx
f0104eef:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104ef2:	eb 06                	jmp    f0104efa <strncmp+0x17>
		n--, p++, q++;
f0104ef4:	83 c0 01             	add    $0x1,%eax
f0104ef7:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0104efa:	39 d8                	cmp    %ebx,%eax
f0104efc:	74 18                	je     f0104f16 <strncmp+0x33>
f0104efe:	0f b6 08             	movzbl (%eax),%ecx
f0104f01:	84 c9                	test   %cl,%cl
f0104f03:	74 04                	je     f0104f09 <strncmp+0x26>
f0104f05:	3a 0a                	cmp    (%edx),%cl
f0104f07:	74 eb                	je     f0104ef4 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104f09:	0f b6 00             	movzbl (%eax),%eax
f0104f0c:	0f b6 12             	movzbl (%edx),%edx
f0104f0f:	29 d0                	sub    %edx,%eax
}
f0104f11:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104f14:	c9                   	leave  
f0104f15:	c3                   	ret    
		return 0;
f0104f16:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f1b:	eb f4                	jmp    f0104f11 <strncmp+0x2e>

f0104f1d <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104f1d:	55                   	push   %ebp
f0104f1e:	89 e5                	mov    %esp,%ebp
f0104f20:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f23:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104f27:	eb 03                	jmp    f0104f2c <strchr+0xf>
f0104f29:	83 c0 01             	add    $0x1,%eax
f0104f2c:	0f b6 10             	movzbl (%eax),%edx
f0104f2f:	84 d2                	test   %dl,%dl
f0104f31:	74 06                	je     f0104f39 <strchr+0x1c>
		if (*s == c)
f0104f33:	38 ca                	cmp    %cl,%dl
f0104f35:	75 f2                	jne    f0104f29 <strchr+0xc>
f0104f37:	eb 05                	jmp    f0104f3e <strchr+0x21>
			return (char *) s;
	return 0;
f0104f39:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104f3e:	5d                   	pop    %ebp
f0104f3f:	c3                   	ret    

f0104f40 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104f40:	55                   	push   %ebp
f0104f41:	89 e5                	mov    %esp,%ebp
f0104f43:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f46:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104f4a:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104f4d:	38 ca                	cmp    %cl,%dl
f0104f4f:	74 09                	je     f0104f5a <strfind+0x1a>
f0104f51:	84 d2                	test   %dl,%dl
f0104f53:	74 05                	je     f0104f5a <strfind+0x1a>
	for (; *s; s++)
f0104f55:	83 c0 01             	add    $0x1,%eax
f0104f58:	eb f0                	jmp    f0104f4a <strfind+0xa>
			break;
	return (char *) s;
}
f0104f5a:	5d                   	pop    %ebp
f0104f5b:	c3                   	ret    

f0104f5c <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104f5c:	55                   	push   %ebp
f0104f5d:	89 e5                	mov    %esp,%ebp
f0104f5f:	57                   	push   %edi
f0104f60:	56                   	push   %esi
f0104f61:	53                   	push   %ebx
f0104f62:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104f65:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104f68:	85 c9                	test   %ecx,%ecx
f0104f6a:	74 2f                	je     f0104f9b <memset+0x3f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104f6c:	89 f8                	mov    %edi,%eax
f0104f6e:	09 c8                	or     %ecx,%eax
f0104f70:	a8 03                	test   $0x3,%al
f0104f72:	75 21                	jne    f0104f95 <memset+0x39>
		c &= 0xFF;
f0104f74:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104f78:	89 d0                	mov    %edx,%eax
f0104f7a:	c1 e0 08             	shl    $0x8,%eax
f0104f7d:	89 d3                	mov    %edx,%ebx
f0104f7f:	c1 e3 18             	shl    $0x18,%ebx
f0104f82:	89 d6                	mov    %edx,%esi
f0104f84:	c1 e6 10             	shl    $0x10,%esi
f0104f87:	09 f3                	or     %esi,%ebx
f0104f89:	09 da                	or     %ebx,%edx
f0104f8b:	09 d0                	or     %edx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104f8d:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0104f90:	fc                   	cld    
f0104f91:	f3 ab                	rep stos %eax,%es:(%edi)
f0104f93:	eb 06                	jmp    f0104f9b <memset+0x3f>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104f95:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104f98:	fc                   	cld    
f0104f99:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104f9b:	89 f8                	mov    %edi,%eax
f0104f9d:	5b                   	pop    %ebx
f0104f9e:	5e                   	pop    %esi
f0104f9f:	5f                   	pop    %edi
f0104fa0:	5d                   	pop    %ebp
f0104fa1:	c3                   	ret    

f0104fa2 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104fa2:	55                   	push   %ebp
f0104fa3:	89 e5                	mov    %esp,%ebp
f0104fa5:	57                   	push   %edi
f0104fa6:	56                   	push   %esi
f0104fa7:	8b 45 08             	mov    0x8(%ebp),%eax
f0104faa:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104fad:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104fb0:	39 c6                	cmp    %eax,%esi
f0104fb2:	73 32                	jae    f0104fe6 <memmove+0x44>
f0104fb4:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104fb7:	39 c2                	cmp    %eax,%edx
f0104fb9:	76 2b                	jbe    f0104fe6 <memmove+0x44>
		s += n;
		d += n;
f0104fbb:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104fbe:	89 d6                	mov    %edx,%esi
f0104fc0:	09 fe                	or     %edi,%esi
f0104fc2:	09 ce                	or     %ecx,%esi
f0104fc4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104fca:	75 0e                	jne    f0104fda <memmove+0x38>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104fcc:	83 ef 04             	sub    $0x4,%edi
f0104fcf:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104fd2:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0104fd5:	fd                   	std    
f0104fd6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104fd8:	eb 09                	jmp    f0104fe3 <memmove+0x41>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104fda:	83 ef 01             	sub    $0x1,%edi
f0104fdd:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0104fe0:	fd                   	std    
f0104fe1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104fe3:	fc                   	cld    
f0104fe4:	eb 1a                	jmp    f0105000 <memmove+0x5e>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104fe6:	89 f2                	mov    %esi,%edx
f0104fe8:	09 c2                	or     %eax,%edx
f0104fea:	09 ca                	or     %ecx,%edx
f0104fec:	f6 c2 03             	test   $0x3,%dl
f0104fef:	75 0a                	jne    f0104ffb <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0104ff1:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0104ff4:	89 c7                	mov    %eax,%edi
f0104ff6:	fc                   	cld    
f0104ff7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104ff9:	eb 05                	jmp    f0105000 <memmove+0x5e>
		else
			asm volatile("cld; rep movsb\n"
f0104ffb:	89 c7                	mov    %eax,%edi
f0104ffd:	fc                   	cld    
f0104ffe:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105000:	5e                   	pop    %esi
f0105001:	5f                   	pop    %edi
f0105002:	5d                   	pop    %ebp
f0105003:	c3                   	ret    

f0105004 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0105004:	55                   	push   %ebp
f0105005:	89 e5                	mov    %esp,%ebp
f0105007:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010500a:	ff 75 10             	push   0x10(%ebp)
f010500d:	ff 75 0c             	push   0xc(%ebp)
f0105010:	ff 75 08             	push   0x8(%ebp)
f0105013:	e8 8a ff ff ff       	call   f0104fa2 <memmove>
}
f0105018:	c9                   	leave  
f0105019:	c3                   	ret    

f010501a <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010501a:	55                   	push   %ebp
f010501b:	89 e5                	mov    %esp,%ebp
f010501d:	56                   	push   %esi
f010501e:	53                   	push   %ebx
f010501f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105022:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105025:	89 c6                	mov    %eax,%esi
f0105027:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010502a:	eb 06                	jmp    f0105032 <memcmp+0x18>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f010502c:	83 c0 01             	add    $0x1,%eax
f010502f:	83 c2 01             	add    $0x1,%edx
	while (n-- > 0) {
f0105032:	39 f0                	cmp    %esi,%eax
f0105034:	74 14                	je     f010504a <memcmp+0x30>
		if (*s1 != *s2)
f0105036:	0f b6 08             	movzbl (%eax),%ecx
f0105039:	0f b6 1a             	movzbl (%edx),%ebx
f010503c:	38 d9                	cmp    %bl,%cl
f010503e:	74 ec                	je     f010502c <memcmp+0x12>
			return (int) *s1 - (int) *s2;
f0105040:	0f b6 c1             	movzbl %cl,%eax
f0105043:	0f b6 db             	movzbl %bl,%ebx
f0105046:	29 d8                	sub    %ebx,%eax
f0105048:	eb 05                	jmp    f010504f <memcmp+0x35>
	}

	return 0;
f010504a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010504f:	5b                   	pop    %ebx
f0105050:	5e                   	pop    %esi
f0105051:	5d                   	pop    %ebp
f0105052:	c3                   	ret    

f0105053 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105053:	55                   	push   %ebp
f0105054:	89 e5                	mov    %esp,%ebp
f0105056:	8b 45 08             	mov    0x8(%ebp),%eax
f0105059:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010505c:	89 c2                	mov    %eax,%edx
f010505e:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105061:	eb 03                	jmp    f0105066 <memfind+0x13>
f0105063:	83 c0 01             	add    $0x1,%eax
f0105066:	39 d0                	cmp    %edx,%eax
f0105068:	73 04                	jae    f010506e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f010506a:	38 08                	cmp    %cl,(%eax)
f010506c:	75 f5                	jne    f0105063 <memfind+0x10>
			break;
	return (void *) s;
}
f010506e:	5d                   	pop    %ebp
f010506f:	c3                   	ret    

f0105070 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105070:	55                   	push   %ebp
f0105071:	89 e5                	mov    %esp,%ebp
f0105073:	57                   	push   %edi
f0105074:	56                   	push   %esi
f0105075:	53                   	push   %ebx
f0105076:	8b 55 08             	mov    0x8(%ebp),%edx
f0105079:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010507c:	eb 03                	jmp    f0105081 <strtol+0x11>
		s++;
f010507e:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f0105081:	0f b6 02             	movzbl (%edx),%eax
f0105084:	3c 20                	cmp    $0x20,%al
f0105086:	74 f6                	je     f010507e <strtol+0xe>
f0105088:	3c 09                	cmp    $0x9,%al
f010508a:	74 f2                	je     f010507e <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f010508c:	3c 2b                	cmp    $0x2b,%al
f010508e:	74 2a                	je     f01050ba <strtol+0x4a>
	int neg = 0;
f0105090:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0105095:	3c 2d                	cmp    $0x2d,%al
f0105097:	74 2b                	je     f01050c4 <strtol+0x54>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105099:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010509f:	75 0f                	jne    f01050b0 <strtol+0x40>
f01050a1:	80 3a 30             	cmpb   $0x30,(%edx)
f01050a4:	74 28                	je     f01050ce <strtol+0x5e>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01050a6:	85 db                	test   %ebx,%ebx
f01050a8:	b8 0a 00 00 00       	mov    $0xa,%eax
f01050ad:	0f 44 d8             	cmove  %eax,%ebx
f01050b0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01050b5:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01050b8:	eb 46                	jmp    f0105100 <strtol+0x90>
		s++;
f01050ba:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f01050bd:	bf 00 00 00 00       	mov    $0x0,%edi
f01050c2:	eb d5                	jmp    f0105099 <strtol+0x29>
		s++, neg = 1;
f01050c4:	83 c2 01             	add    $0x1,%edx
f01050c7:	bf 01 00 00 00       	mov    $0x1,%edi
f01050cc:	eb cb                	jmp    f0105099 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01050ce:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01050d2:	74 0e                	je     f01050e2 <strtol+0x72>
	else if (base == 0 && s[0] == '0')
f01050d4:	85 db                	test   %ebx,%ebx
f01050d6:	75 d8                	jne    f01050b0 <strtol+0x40>
		s++, base = 8;
f01050d8:	83 c2 01             	add    $0x1,%edx
f01050db:	bb 08 00 00 00       	mov    $0x8,%ebx
f01050e0:	eb ce                	jmp    f01050b0 <strtol+0x40>
		s += 2, base = 16;
f01050e2:	83 c2 02             	add    $0x2,%edx
f01050e5:	bb 10 00 00 00       	mov    $0x10,%ebx
f01050ea:	eb c4                	jmp    f01050b0 <strtol+0x40>
	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
f01050ec:	0f be c0             	movsbl %al,%eax
f01050ef:	83 e8 30             	sub    $0x30,%eax
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01050f2:	3b 45 10             	cmp    0x10(%ebp),%eax
f01050f5:	7d 3a                	jge    f0105131 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f01050f7:	83 c2 01             	add    $0x1,%edx
f01050fa:	0f af 4d 10          	imul   0x10(%ebp),%ecx
f01050fe:	01 c1                	add    %eax,%ecx
		if (*s >= '0' && *s <= '9')
f0105100:	0f b6 02             	movzbl (%edx),%eax
f0105103:	8d 70 d0             	lea    -0x30(%eax),%esi
f0105106:	89 f3                	mov    %esi,%ebx
f0105108:	80 fb 09             	cmp    $0x9,%bl
f010510b:	76 df                	jbe    f01050ec <strtol+0x7c>
		else if (*s >= 'a' && *s <= 'z')
f010510d:	8d 70 9f             	lea    -0x61(%eax),%esi
f0105110:	89 f3                	mov    %esi,%ebx
f0105112:	80 fb 19             	cmp    $0x19,%bl
f0105115:	77 08                	ja     f010511f <strtol+0xaf>
			dig = *s - 'a' + 10;
f0105117:	0f be c0             	movsbl %al,%eax
f010511a:	83 e8 57             	sub    $0x57,%eax
f010511d:	eb d3                	jmp    f01050f2 <strtol+0x82>
		else if (*s >= 'A' && *s <= 'Z')
f010511f:	8d 70 bf             	lea    -0x41(%eax),%esi
f0105122:	89 f3                	mov    %esi,%ebx
f0105124:	80 fb 19             	cmp    $0x19,%bl
f0105127:	77 08                	ja     f0105131 <strtol+0xc1>
			dig = *s - 'A' + 10;
f0105129:	0f be c0             	movsbl %al,%eax
f010512c:	83 e8 37             	sub    $0x37,%eax
f010512f:	eb c1                	jmp    f01050f2 <strtol+0x82>
		// we don't properly detect overflow!
	}

	if (endptr)
f0105131:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105135:	74 05                	je     f010513c <strtol+0xcc>
		*endptr = (char *) s;
f0105137:	8b 45 0c             	mov    0xc(%ebp),%eax
f010513a:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
f010513c:	89 c8                	mov    %ecx,%eax
f010513e:	f7 d8                	neg    %eax
f0105140:	85 ff                	test   %edi,%edi
f0105142:	0f 45 c8             	cmovne %eax,%ecx
}
f0105145:	89 c8                	mov    %ecx,%eax
f0105147:	5b                   	pop    %ebx
f0105148:	5e                   	pop    %esi
f0105149:	5f                   	pop    %edi
f010514a:	5d                   	pop    %ebp
f010514b:	c3                   	ret    
f010514c:	66 90                	xchg   %ax,%ax
f010514e:	66 90                	xchg   %ax,%ax

f0105150 <__udivdi3>:
f0105150:	f3 0f 1e fb          	endbr32 
f0105154:	55                   	push   %ebp
f0105155:	57                   	push   %edi
f0105156:	56                   	push   %esi
f0105157:	53                   	push   %ebx
f0105158:	83 ec 1c             	sub    $0x1c,%esp
f010515b:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010515f:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0105163:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105167:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f010516b:	85 c0                	test   %eax,%eax
f010516d:	75 19                	jne    f0105188 <__udivdi3+0x38>
f010516f:	39 f3                	cmp    %esi,%ebx
f0105171:	76 4d                	jbe    f01051c0 <__udivdi3+0x70>
f0105173:	31 ff                	xor    %edi,%edi
f0105175:	89 e8                	mov    %ebp,%eax
f0105177:	89 f2                	mov    %esi,%edx
f0105179:	f7 f3                	div    %ebx
f010517b:	89 fa                	mov    %edi,%edx
f010517d:	83 c4 1c             	add    $0x1c,%esp
f0105180:	5b                   	pop    %ebx
f0105181:	5e                   	pop    %esi
f0105182:	5f                   	pop    %edi
f0105183:	5d                   	pop    %ebp
f0105184:	c3                   	ret    
f0105185:	8d 76 00             	lea    0x0(%esi),%esi
f0105188:	39 f0                	cmp    %esi,%eax
f010518a:	76 14                	jbe    f01051a0 <__udivdi3+0x50>
f010518c:	31 ff                	xor    %edi,%edi
f010518e:	31 c0                	xor    %eax,%eax
f0105190:	89 fa                	mov    %edi,%edx
f0105192:	83 c4 1c             	add    $0x1c,%esp
f0105195:	5b                   	pop    %ebx
f0105196:	5e                   	pop    %esi
f0105197:	5f                   	pop    %edi
f0105198:	5d                   	pop    %ebp
f0105199:	c3                   	ret    
f010519a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01051a0:	0f bd f8             	bsr    %eax,%edi
f01051a3:	83 f7 1f             	xor    $0x1f,%edi
f01051a6:	75 48                	jne    f01051f0 <__udivdi3+0xa0>
f01051a8:	39 f0                	cmp    %esi,%eax
f01051aa:	72 06                	jb     f01051b2 <__udivdi3+0x62>
f01051ac:	31 c0                	xor    %eax,%eax
f01051ae:	39 eb                	cmp    %ebp,%ebx
f01051b0:	77 de                	ja     f0105190 <__udivdi3+0x40>
f01051b2:	b8 01 00 00 00       	mov    $0x1,%eax
f01051b7:	eb d7                	jmp    f0105190 <__udivdi3+0x40>
f01051b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01051c0:	89 d9                	mov    %ebx,%ecx
f01051c2:	85 db                	test   %ebx,%ebx
f01051c4:	75 0b                	jne    f01051d1 <__udivdi3+0x81>
f01051c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01051cb:	31 d2                	xor    %edx,%edx
f01051cd:	f7 f3                	div    %ebx
f01051cf:	89 c1                	mov    %eax,%ecx
f01051d1:	31 d2                	xor    %edx,%edx
f01051d3:	89 f0                	mov    %esi,%eax
f01051d5:	f7 f1                	div    %ecx
f01051d7:	89 c6                	mov    %eax,%esi
f01051d9:	89 e8                	mov    %ebp,%eax
f01051db:	89 f7                	mov    %esi,%edi
f01051dd:	f7 f1                	div    %ecx
f01051df:	89 fa                	mov    %edi,%edx
f01051e1:	83 c4 1c             	add    $0x1c,%esp
f01051e4:	5b                   	pop    %ebx
f01051e5:	5e                   	pop    %esi
f01051e6:	5f                   	pop    %edi
f01051e7:	5d                   	pop    %ebp
f01051e8:	c3                   	ret    
f01051e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01051f0:	89 f9                	mov    %edi,%ecx
f01051f2:	ba 20 00 00 00       	mov    $0x20,%edx
f01051f7:	29 fa                	sub    %edi,%edx
f01051f9:	d3 e0                	shl    %cl,%eax
f01051fb:	89 44 24 08          	mov    %eax,0x8(%esp)
f01051ff:	89 d1                	mov    %edx,%ecx
f0105201:	89 d8                	mov    %ebx,%eax
f0105203:	d3 e8                	shr    %cl,%eax
f0105205:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0105209:	09 c1                	or     %eax,%ecx
f010520b:	89 f0                	mov    %esi,%eax
f010520d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105211:	89 f9                	mov    %edi,%ecx
f0105213:	d3 e3                	shl    %cl,%ebx
f0105215:	89 d1                	mov    %edx,%ecx
f0105217:	d3 e8                	shr    %cl,%eax
f0105219:	89 f9                	mov    %edi,%ecx
f010521b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010521f:	89 eb                	mov    %ebp,%ebx
f0105221:	d3 e6                	shl    %cl,%esi
f0105223:	89 d1                	mov    %edx,%ecx
f0105225:	d3 eb                	shr    %cl,%ebx
f0105227:	09 f3                	or     %esi,%ebx
f0105229:	89 c6                	mov    %eax,%esi
f010522b:	89 f2                	mov    %esi,%edx
f010522d:	89 d8                	mov    %ebx,%eax
f010522f:	f7 74 24 08          	divl   0x8(%esp)
f0105233:	89 d6                	mov    %edx,%esi
f0105235:	89 c3                	mov    %eax,%ebx
f0105237:	f7 64 24 0c          	mull   0xc(%esp)
f010523b:	39 d6                	cmp    %edx,%esi
f010523d:	72 19                	jb     f0105258 <__udivdi3+0x108>
f010523f:	89 f9                	mov    %edi,%ecx
f0105241:	d3 e5                	shl    %cl,%ebp
f0105243:	39 c5                	cmp    %eax,%ebp
f0105245:	73 04                	jae    f010524b <__udivdi3+0xfb>
f0105247:	39 d6                	cmp    %edx,%esi
f0105249:	74 0d                	je     f0105258 <__udivdi3+0x108>
f010524b:	89 d8                	mov    %ebx,%eax
f010524d:	31 ff                	xor    %edi,%edi
f010524f:	e9 3c ff ff ff       	jmp    f0105190 <__udivdi3+0x40>
f0105254:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105258:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010525b:	31 ff                	xor    %edi,%edi
f010525d:	e9 2e ff ff ff       	jmp    f0105190 <__udivdi3+0x40>
f0105262:	66 90                	xchg   %ax,%ax
f0105264:	66 90                	xchg   %ax,%ax
f0105266:	66 90                	xchg   %ax,%ax
f0105268:	66 90                	xchg   %ax,%ax
f010526a:	66 90                	xchg   %ax,%ax
f010526c:	66 90                	xchg   %ax,%ax
f010526e:	66 90                	xchg   %ax,%ax

f0105270 <__umoddi3>:
f0105270:	f3 0f 1e fb          	endbr32 
f0105274:	55                   	push   %ebp
f0105275:	57                   	push   %edi
f0105276:	56                   	push   %esi
f0105277:	53                   	push   %ebx
f0105278:	83 ec 1c             	sub    $0x1c,%esp
f010527b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010527f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0105283:	8b 7c 24 3c          	mov    0x3c(%esp),%edi
f0105287:	8b 6c 24 38          	mov    0x38(%esp),%ebp
f010528b:	89 f0                	mov    %esi,%eax
f010528d:	89 da                	mov    %ebx,%edx
f010528f:	85 ff                	test   %edi,%edi
f0105291:	75 15                	jne    f01052a8 <__umoddi3+0x38>
f0105293:	39 dd                	cmp    %ebx,%ebp
f0105295:	76 39                	jbe    f01052d0 <__umoddi3+0x60>
f0105297:	f7 f5                	div    %ebp
f0105299:	89 d0                	mov    %edx,%eax
f010529b:	31 d2                	xor    %edx,%edx
f010529d:	83 c4 1c             	add    $0x1c,%esp
f01052a0:	5b                   	pop    %ebx
f01052a1:	5e                   	pop    %esi
f01052a2:	5f                   	pop    %edi
f01052a3:	5d                   	pop    %ebp
f01052a4:	c3                   	ret    
f01052a5:	8d 76 00             	lea    0x0(%esi),%esi
f01052a8:	39 df                	cmp    %ebx,%edi
f01052aa:	77 f1                	ja     f010529d <__umoddi3+0x2d>
f01052ac:	0f bd cf             	bsr    %edi,%ecx
f01052af:	83 f1 1f             	xor    $0x1f,%ecx
f01052b2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01052b6:	75 40                	jne    f01052f8 <__umoddi3+0x88>
f01052b8:	39 df                	cmp    %ebx,%edi
f01052ba:	72 04                	jb     f01052c0 <__umoddi3+0x50>
f01052bc:	39 f5                	cmp    %esi,%ebp
f01052be:	77 dd                	ja     f010529d <__umoddi3+0x2d>
f01052c0:	89 da                	mov    %ebx,%edx
f01052c2:	89 f0                	mov    %esi,%eax
f01052c4:	29 e8                	sub    %ebp,%eax
f01052c6:	19 fa                	sbb    %edi,%edx
f01052c8:	eb d3                	jmp    f010529d <__umoddi3+0x2d>
f01052ca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01052d0:	89 e9                	mov    %ebp,%ecx
f01052d2:	85 ed                	test   %ebp,%ebp
f01052d4:	75 0b                	jne    f01052e1 <__umoddi3+0x71>
f01052d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01052db:	31 d2                	xor    %edx,%edx
f01052dd:	f7 f5                	div    %ebp
f01052df:	89 c1                	mov    %eax,%ecx
f01052e1:	89 d8                	mov    %ebx,%eax
f01052e3:	31 d2                	xor    %edx,%edx
f01052e5:	f7 f1                	div    %ecx
f01052e7:	89 f0                	mov    %esi,%eax
f01052e9:	f7 f1                	div    %ecx
f01052eb:	89 d0                	mov    %edx,%eax
f01052ed:	31 d2                	xor    %edx,%edx
f01052ef:	eb ac                	jmp    f010529d <__umoddi3+0x2d>
f01052f1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01052f8:	8b 44 24 04          	mov    0x4(%esp),%eax
f01052fc:	ba 20 00 00 00       	mov    $0x20,%edx
f0105301:	29 c2                	sub    %eax,%edx
f0105303:	89 c1                	mov    %eax,%ecx
f0105305:	89 e8                	mov    %ebp,%eax
f0105307:	d3 e7                	shl    %cl,%edi
f0105309:	89 d1                	mov    %edx,%ecx
f010530b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010530f:	d3 e8                	shr    %cl,%eax
f0105311:	89 c1                	mov    %eax,%ecx
f0105313:	8b 44 24 04          	mov    0x4(%esp),%eax
f0105317:	09 f9                	or     %edi,%ecx
f0105319:	89 df                	mov    %ebx,%edi
f010531b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010531f:	89 c1                	mov    %eax,%ecx
f0105321:	d3 e5                	shl    %cl,%ebp
f0105323:	89 d1                	mov    %edx,%ecx
f0105325:	d3 ef                	shr    %cl,%edi
f0105327:	89 c1                	mov    %eax,%ecx
f0105329:	89 f0                	mov    %esi,%eax
f010532b:	d3 e3                	shl    %cl,%ebx
f010532d:	89 d1                	mov    %edx,%ecx
f010532f:	89 fa                	mov    %edi,%edx
f0105331:	d3 e8                	shr    %cl,%eax
f0105333:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0105338:	09 d8                	or     %ebx,%eax
f010533a:	f7 74 24 08          	divl   0x8(%esp)
f010533e:	89 d3                	mov    %edx,%ebx
f0105340:	d3 e6                	shl    %cl,%esi
f0105342:	f7 e5                	mul    %ebp
f0105344:	89 c7                	mov    %eax,%edi
f0105346:	89 d1                	mov    %edx,%ecx
f0105348:	39 d3                	cmp    %edx,%ebx
f010534a:	72 06                	jb     f0105352 <__umoddi3+0xe2>
f010534c:	75 0e                	jne    f010535c <__umoddi3+0xec>
f010534e:	39 c6                	cmp    %eax,%esi
f0105350:	73 0a                	jae    f010535c <__umoddi3+0xec>
f0105352:	29 e8                	sub    %ebp,%eax
f0105354:	1b 54 24 08          	sbb    0x8(%esp),%edx
f0105358:	89 d1                	mov    %edx,%ecx
f010535a:	89 c7                	mov    %eax,%edi
f010535c:	89 f5                	mov    %esi,%ebp
f010535e:	8b 74 24 04          	mov    0x4(%esp),%esi
f0105362:	29 fd                	sub    %edi,%ebp
f0105364:	19 cb                	sbb    %ecx,%ebx
f0105366:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f010536b:	89 d8                	mov    %ebx,%eax
f010536d:	d3 e0                	shl    %cl,%eax
f010536f:	89 f1                	mov    %esi,%ecx
f0105371:	d3 ed                	shr    %cl,%ebp
f0105373:	d3 eb                	shr    %cl,%ebx
f0105375:	09 e8                	or     %ebp,%eax
f0105377:	89 da                	mov    %ebx,%edx
f0105379:	83 c4 1c             	add    $0x1c,%esp
f010537c:	5b                   	pop    %ebx
f010537d:	5e                   	pop    %esi
f010537e:	5f                   	pop    %edi
f010537f:	5d                   	pop    %ebp
f0105380:	c3                   	ret    
