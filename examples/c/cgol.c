/* cgol.c
   - freestanding ANSI C cellular automaton
*/

typedef unsigned char T0;
typedef unsigned char T1;
typedef unsigned char T2;

#ifndef P0
#define P0 16u
#endif

#ifndef P1
#define P1 8u
#endif

#define P2 (P0 * P1)
#define P3 ((P2 + 7u) / 8u)

#if (P0 < 1u) || (P1 < 1u)
#error P0 and P1 must be >= 1
#endif

#if (P2 > 255u)
#error P0*P1 must be <= 255 for this build (keeps all indexes 8-bit)
#endif

static T0 V0[P3];
static T0 V1[P3];

static T0 *V2;
static T0 *V3;

static void F0(T0 *a0) {
  T1 i;
  for (i = 0; i < (T1)P3; i++) {
    a0[i] = (T0)0u;
  }
}

static T2 F1(const T0 *a0, T1 a1) {
  T1 b;
  T0 m;
  b = (T1)(a1 >> 3);
  m = (T0)((T0)1u << (a1 & (T1)7u));
  return (a0[b] & m) ? (T2)1u : (T2)0u;
}

static void F2(T0 *a0, T1 a1, T2 a2) {
  T1 b;
  T0 m;
  b = (T1)(a1 >> 3);
  m = (T0)((T0)1u << (a1 & (T1)7u));
  if (a2) {
    a0[b] = (T0)(a0[b] | m);
  } else {
    a0[b] = (T0)(a0[b] & (T0)(~m));
  }
}

static T1 F3(T1 a0, T1 a1) {
  T1 i;
  i = a0;
  while (a1) {
    i = (T1)(i + (T1)P0);
    a1--;
  }
  return i;
}

static void F4(T0 *a0) {
  F0(a0);

  if ((P0 >= 3u) && (P1 >= 3u)) {
    F2(a0, F3((T1)1u, (T1)0u), (T2)1u);
    F2(a0, F3((T1)2u, (T1)1u), (T2)1u);
    F2(a0, F3((T1)0u, (T1)2u), (T2)1u);
    F2(a0, F3((T1)1u, (T1)2u), (T2)1u);
    F2(a0, F3((T1)2u, (T1)2u), (T2)1u);
  }
}

static void F5(const T0 *a0, T0 *a1) {
  T1 y, x;
  T1 b0, bu, bd;
  T1 xl, xr;
  T1 i;
  T1 n;

  F0(a1);

  b0 = (T1)0u;
  for (y = 0; y < (T1)P1; y++) {
    if (y == (T1)0u) {
      bu = (T1)(P2 - P0);
    } else {
      bu = (T1)(b0 - (T1)P0);
    }

    if (y == (T1)(P1 - 1u)) {
      bd = (T1)0u;
    } else {
      bd = (T1)(b0 + (T1)P0);
    }

    for (x = 0; x < (T1)P0; x++) {
      if (x == (T1)0u) {
        xl = (T1)(P0 - 1u);
      } else {
        xl = (T1)(x - 1u);
      }

      if (x == (T1)(P0 - 1u)) {
        xr = (T1)0u;
      } else {
        xr = (T1)(x + 1u);
      }

      n = (T1)0u;

      n = (T1)(n + F1(a0, (T1)(bu + xl)));
      n = (T1)(n + F1(a0, (T1)(bu + x)));
      n = (T1)(n + F1(a0, (T1)(bu + xr)));

      n = (T1)(n + F1(a0, (T1)(b0 + xl)));
      n = (T1)(n + F1(a0, (T1)(b0 + xr)));

      n = (T1)(n + F1(a0, (T1)(bd + xl)));
      n = (T1)(n + F1(a0, (T1)(bd + x)));
      n = (T1)(n + F1(a0, (T1)(bd + xr)));

      i = (T1)(b0 + x);

      if (F1(a0, i)) {
        if ((n == (T1)2u) || (n == (T1)3u)) {
          F2(a1, i, (T2)1u);
        }
      } else {
        if (n == (T1)3u) {
          F2(a1, i, (T2)1u);
        }
      }
    }

    b0 = (T1)(b0 + (T1)P0);
  }
}

void F6(void) {
  V2 = V0;
  V3 = V1;
  F4(V2);
}

void F7(void) {
  T0 *t;
  F5(V2, V3);
  t = V2;
  V2 = V3;
  V3 = t;
}

const T0 *F8(void) { return (const T0 *)V2; }
