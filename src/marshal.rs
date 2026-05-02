//! Minimal Ruby Marshal codec — only enough to (de)serialise UTF-8 strings.
//!
//! `ActiveSupport::EncryptedFile` uses Marshal as its inner serializer, so to
//! be wire-compatible with the existing Ruby tool we have to produce and
//! consume Marshal-formatted strings.
//!
//! Marshal layout for a UTF-8 String:
//!   \x04\x08    version (4.8)
//!   I           IVAR wrapper (0x49)
//!   "           String type (0x22)
//!   <fixnum>    byte length, encoded as a Marshal Fixnum
//!   <bytes>     raw UTF-8 bytes
//!   <fixnum=1>  one instance variable follows
//!   :           Symbol type (0x3A)
//!   <fixnum=1>  symbol name length
//!   E           "E" — the encoding flag
//!   T           true — meaning UTF-8 (Encoding::UTF_8)
//!
//! Fixnum encoding (positive only, which is all we need for length):
//!   0           -> 0x00
//!   1..=122     -> single byte (n + 5)
//!   else        -> 0x01..=0x04 indicating byte count, then little-endian bytes

use anyhow::{bail, Context, Result};

const VERSION: [u8; 2] = [0x04, 0x08];

pub fn dump_utf8_string(s: &str) -> Vec<u8> {
    let bytes = s.as_bytes();
    let mut out = Vec::with_capacity(bytes.len() + 16);
    out.extend_from_slice(&VERSION);
    out.push(b'I');
    out.push(b'"');
    write_fixnum(&mut out, bytes.len() as i64);
    out.extend_from_slice(bytes);
    write_fixnum(&mut out, 1); // one ivar
    out.push(b':');
    write_fixnum(&mut out, 1); // symbol length
    out.push(b'E');
    out.push(b'T');
    out
}

pub fn load_utf8_string(data: &[u8]) -> Result<String> {
    let mut p = Parser::new(data);
    p.expect(&VERSION).context("checking Marshal version")?;
    p.expect(b"I").context("expecting IVAR")?;
    p.expect(b"\"").context("expecting String")?;
    let len = p.read_fixnum().context("reading string length")?;
    if len < 0 {
        bail!("negative string length");
    }
    let bytes = p.take(len as usize).context("reading string bytes")?;
    let result =
        std::str::from_utf8(bytes).context("string was not valid UTF-8")?.to_owned();
    // We don't validate the trailing ivar block — if Ruby wrote it, it's fine,
    // and unknown ivars don't change the string content.
    Ok(result)
}

struct Parser<'a> {
    buf: &'a [u8],
    pos: usize,
}

impl<'a> Parser<'a> {
    fn new(buf: &'a [u8]) -> Self {
        Self { buf, pos: 0 }
    }

    fn expect(&mut self, want: &[u8]) -> Result<()> {
        let got = self.take(want.len())?;
        if got != want {
            bail!("expected {:x?}, got {:x?}", want, got);
        }
        Ok(())
    }

    fn take(&mut self, n: usize) -> Result<&'a [u8]> {
        if self.pos + n > self.buf.len() {
            bail!("unexpected end of marshal stream");
        }
        let slice = &self.buf[self.pos..self.pos + n];
        self.pos += n;
        Ok(slice)
    }

    fn read_byte(&mut self) -> Result<u8> {
        Ok(self.take(1)?[0])
    }

    fn read_fixnum(&mut self) -> Result<i64> {
        let b = self.read_byte()? as i8;
        match b {
            0 => Ok(0),
            1..=4 => {
                let n = b as usize;
                let bytes = self.take(n)?;
                let mut v: u64 = 0;
                for (i, byte) in bytes.iter().enumerate() {
                    v |= (*byte as u64) << (i * 8);
                }
                Ok(v as i64)
            }
            -4..=-1 => {
                let n = (-b) as usize;
                let bytes = self.take(n)?;
                let mut v: i64 = -1;
                for (i, byte) in bytes.iter().enumerate() {
                    v &= !(0xff << (i * 8));
                    v |= (*byte as i64) << (i * 8);
                }
                Ok(v)
            }
            5..=127 => Ok(b as i64 - 5),
            -128..=-6 => Ok(b as i64 + 5),
            -5 => bail!("invalid fixnum byte -5"),
        }
    }
}

fn write_fixnum(out: &mut Vec<u8>, n: i64) {
    if n == 0 {
        out.push(0);
    } else if (1..=122).contains(&n) {
        out.push((n + 5) as u8);
    } else if (-123..=-1).contains(&n) {
        out.push((n - 5) as i8 as u8);
    } else if n > 0 {
        let mut buf = [0u8; 8];
        let mut len = 0;
        let mut v = n as u64;
        while v > 0 && len < 4 {
            buf[len] = (v & 0xff) as u8;
            v >>= 8;
            len += 1;
        }
        out.push(len as u8);
        out.extend_from_slice(&buf[..len]);
    } else {
        // negative — mirror image; not used for lengths but provided for completeness
        let mut buf = [0u8; 8];
        let mut len = 0;
        let mut v = n;
        while v != -1 && len < 4 {
            buf[len] = (v & 0xff) as u8;
            v >>= 8;
            len += 1;
        }
        out.push((-(len as i8)) as u8);
        out.extend_from_slice(&buf[..len]);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn roundtrip_short() {
        let s = "hello";
        let encoded = dump_utf8_string(s);
        assert_eq!(load_utf8_string(&encoded).unwrap(), s);
    }

    #[test]
    fn roundtrip_long() {
        let s = "a".repeat(10000);
        let encoded = dump_utf8_string(&s);
        assert_eq!(load_utf8_string(&encoded).unwrap(), s);
    }

    #[test]
    fn roundtrip_utf8() {
        let s = "héllo 🎉 こんにちは";
        let encoded = dump_utf8_string(s);
        assert_eq!(load_utf8_string(&encoded).unwrap(), s);
    }
}
