import { useEffect, useState } from 'react';
import { useRouter } from 'next/router';

export default function PaymentSuccess() {
  const router = useRouter();
  const { orderId } = router.query;
  const [countdown, setCountdown] = useState(5);

  useEffect(() => {
    // Countdown timer
    const countdownInterval = setInterval(() => {
      setCountdown((prev) => {
        if (prev <= 1) {
          clearInterval(countdownInterval);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    // Redirect to Flutter app after 5 seconds
    const redirectTimer = setTimeout(() => {
      const redirectUrl = `delicious://payment/success?orderId=${orderId || ''}`;
      window.location.href = redirectUrl;
    }, 5000);

    return () => {
      clearInterval(countdownInterval);
      clearTimeout(redirectTimer);
    };
  }, [orderId]);

  return (
    <div style={styles.container}>
      {/* Animated background */}
      <div style={styles.backgroundAnimation} />
      
      <div style={styles.content}>
        {/* Success Animation */}
        <div style={styles.animationContainer}>
          <div style={styles.checkmarkCircle}>
            <svg 
              style={styles.checkmark} 
              fill="none" 
              stroke="white" 
              viewBox="0 0 24 24"
            >
              <path 
                strokeLinecap="round" 
                strokeLinejoin="round" 
                strokeWidth={3} 
                d="M5 13l4 4L19 7" 
              />
            </svg>
          </div>
        </div>

        {/* Title */}
        <h1 style={styles.title}>Payment Successful!</h1>
        
        {/* Subtitle */}
        <p style={styles.subtitle}>
          Thank you for your order. Your payment has been confirmed.
        </p>

        {/* Order Details Card */}
        {orderId && (
          <div style={styles.orderCard}>
            <div style={styles.orderRow}>
              <span style={styles.orderLabel}>Order Number:</span>
              <span style={styles.orderValue}>#{orderId}</span>
            </div>
            <div style={styles.orderRow}>
              <span style={styles.orderLabel}>Status:</span>
              <span style={styles.orderStatus}>✓ Confirmed</span>
            </div>
          </div>
        )}

        {/* Loading Indicator */}
        <div style={styles.loadingContainer}>
          <div style={styles.loader} />
          <p style={styles.redirectText}>
            Redirecting back to the app in {countdown} seconds...
          </p>
        </div>

        {/* Manual Redirect Link */}
        <button 
          onClick={() => {
            const redirectUrl = `delicious://payment/success?orderId=${orderId || ''}`;
            window.location.href = redirectUrl;
          }}
          style={styles.button}
        >
          Return to App Now
        </button>
      </div>

      {/* Decorative Elements */}
      <div style={styles.decorativeCircle1} />
      <div style={styles.decorativeCircle2} />
    </div>
  );
}

// Professional CSS styles
const styles: { [key: string]: React.CSSProperties } = {
  container: {
    minHeight: '100vh',
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
    position: 'relative',
    overflow: 'hidden',
  },
  backgroundAnimation: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    background: 'radial-gradient(circle at 30% 50%, rgba(255,255,255,0.1) 0%, transparent 50%)',
    animation: 'pulse 4s ease-in-out infinite',
  },
  content: {
    textAlign: 'center',
    zIndex: 2,
    maxWidth: '500px',
    padding: '40px 20px',
  },
  animationContainer: {
    marginBottom: '32px',
  },
  checkmarkCircle: {
    width: '100px',
    height: '100px',
    backgroundColor: '#10b981',
    borderRadius: '50%',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    margin: '0 auto',
    animation: 'scaleIn 0.5s ease-out, bounce 1s ease-in-out 0.5s',
    boxShadow: '0 10px 40px rgba(16, 185, 129, 0.3)',
  },
  checkmark: {
    width: '50px',
    height: '50px',
    animation: 'drawCheck 0.5s ease-out 0.3s both',
  },
  title: {
    fontSize: '32px',
    fontWeight: '700',
    color: 'white',
    marginBottom: '12px',
    textShadow: '0 2px 4px rgba(0,0,0,0.1)',
    animation: 'fadeInUp 0.5s ease-out 0.2s both',
  },
  subtitle: {
    fontSize: '16px',
    color: 'rgba(255,255,255,0.9)',
    marginBottom: '32px',
    lineHeight: '1.5',
    animation: 'fadeInUp 0.5s ease-out 0.3s both',
  },
  orderCard: {
    backgroundColor: 'rgba(255,255,255,0.15)',
    backdropFilter: 'blur(10px)',
    borderRadius: '16px',
    padding: '20px',
    marginBottom: '32px',
    textAlign: 'left',
    animation: 'fadeInUp 0.5s ease-out 0.4s both',
    border: '1px solid rgba(255,255,255,0.2)',
  },
  orderRow: {
    display: 'flex',
    justifyContent: 'space-between',
    padding: '8px 0',
  },
  orderLabel: {
    color: 'rgba(255,255,255,0.7)',
    fontSize: '14px',
  },
  orderValue: {
    color: 'white',
    fontWeight: '600',
    fontSize: '14px',
  },
  orderStatus: {
    color: '#10b981',
    fontWeight: '600',
    fontSize: '14px',
  },
  loadingContainer: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: '12px',
    marginBottom: '24px',
    animation: 'fadeInUp 0.5s ease-out 0.5s both',
  },
  loader: {
    width: '20px',
    height: '20px',
    border: '2px solid rgba(255,255,255,0.3)',
    borderTop: '2px solid white',
    borderRadius: '50%',
    animation: 'spin 1s linear infinite',
  },
  redirectText: {
    color: 'rgba(255,255,255,0.8)',
    fontSize: '14px',
  },
  button: {
    backgroundColor: 'white',
    color: '#667eea',
    border: 'none',
    padding: '12px 32px',
    borderRadius: '50px',
    fontSize: '16px',
    fontWeight: '600',
    cursor: 'pointer',
    transition: 'all 0.3s ease',
    boxShadow: '0 4px 15px rgba(0,0,0,0.1)',
    animation: 'fadeInUp 0.5s ease-out 0.6s both',
  },
  decorativeCircle1: {
    position: 'absolute',
    top: '-100px',
    right: '-100px',
    width: '300px',
    height: '300px',
    borderRadius: '50%',
    background: 'radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 70%)',
    zIndex: 1,
  },
  decorativeCircle2: {
    position: 'absolute',
    bottom: '-100px',
    left: '-100px',
    width: '250px',
    height: '250px',
    borderRadius: '50%',
    background: 'radial-gradient(circle, rgba(255,255,255,0.08) 0%, transparent 70%)',
    zIndex: 1,
  },
};

// Add CSS animations to the page
const animationStyles = `
  @keyframes pulse {
    0%, 100% { opacity: 0.5; }
    50% { opacity: 1; }
  }
  @keyframes scaleIn {
    0% { transform: scale(0); opacity: 0; }
    80% { transform: scale(1.1); }
    100% { transform: scale(1); opacity: 1; }
  }
  @keyframes bounce {
    0%, 100% { transform: translateY(0); }
    50% { transform: translateY(-10px); }
  }
  @keyframes drawCheck {
    0% { stroke-dasharray: 100; stroke-dashoffset: 100; opacity: 0; }
    100% { stroke-dasharray: 100; stroke-dashoffset: 0; opacity: 1; }
  }
  @keyframes fadeInUp {
    0% { opacity: 0; transform: translateY(20px); }
    100% { opacity: 1; transform: translateY(0); }
  }
  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
`;

// Inject animations into the page
if (typeof document !== 'undefined') {
  const styleSheet = document.createElement('style');
  styleSheet.textContent = animationStyles;
  document.head.appendChild(styleSheet);
}