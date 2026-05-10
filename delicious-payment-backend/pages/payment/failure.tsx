import { useEffect, useState } from 'react';
import { useRouter } from 'next/router';

export default function PaymentFailure() {
  const router = useRouter();
  const { orderId } = router.query;
  const [countdown, setCountdown] = useState(5);

  useEffect(() => {
    const countdownInterval = setInterval(() => {
      setCountdown((prev) => {
        if (prev <= 1) {
          clearInterval(countdownInterval);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    const redirectTimer = setTimeout(() => {
      const redirectUrl = `delicious://payment/failure?orderId=${orderId || ''}`;
      window.location.href = redirectUrl;
    }, 5000);

    return () => {
      clearInterval(countdownInterval);
      clearTimeout(redirectTimer);
    };
  }, [orderId]);

  return (
    <div style={faliureStyles.container}>
      <div style={faliureStyles.backgroundAnimation} />
      
      <div style={faliureStyles.content}>
        {/* Failure Animation */}
        <div style={faliureStyles.animationContainer}>
          <div style={faliureStyles.crossCircle}>
            <svg 
              style={faliureStyles.cross} 
              fill="none" 
              stroke="white" 
              viewBox="0 0 24 24"
            >
              <path 
                strokeLinecap="round" 
                strokeLinejoin="round" 
                strokeWidth={3} 
                d="M6 18L18 6M6 6l12 12" 
              />
            </svg>
          </div>
        </div>

        {/* Title */}
        <h1 style={faliureStyles.title}>Payment Failed</h1>
        
        {/* Subtitle */}
        <p style={faliureStyles.subtitle}>
         We could not process your payment. Please try again or use a different payment method.
        </p>

        {/* Help Card */}
        <div style={faliureStyles.helpCard}>
          <h3 style={faliureStyles.helpTitle}>Need help?</h3>
          <p style={faliureStyles.helpText}>
            Contact our support team at <strong>support@delicious.dz</strong>
          </p>
          <p style={faliureStyles.helpTextSmall}>
            Reference: {orderId || 'N/A'}
          </p>
        </div>

        {/* Loading Indicator */}
        <div style={faliureStyles.loadingContainer}>
          <div style={faliureStyles.loader} />
          <p style={faliureStyles.redirectText}>
            Redirecting back to the app in {countdown} seconds...
          </p>
        </div>

        {/* Action Buttons */}
        <div style={faliureStyles.buttonGroup}>
          <button 
            onClick={() => {
              const redirectUrl = `delicious://payment/failure?orderId={orderId || ''}`;
              window.location.href = redirectUrl;
            }}
            style={faliureStyles.buttonPrimary}
          >
            Return to App
          </button>
          <button 
            onClick={() => window.location.href = '/'}
            style={faliureStyles.buttonSecondary}
          >
            Try Again
          </button>
        </div>
      </div>

      <div style={faliureStyles.decorativeCircle1} />
      <div style={faliureStyles.decorativeCircle2} />
    </div>
  );
}

const faliureStyles: { [key: string]: React.CSSProperties } = {
  container: {
    minHeight: '100vh',
    background: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
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
    background: 'radial-gradient(circle at 70% 50%, rgba(255,255,255,0.1) 0%, transparent 50%)',
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
  crossCircle: {
    width: '100px',
    height: '100px',
    backgroundColor: '#ef4444',
    borderRadius: '50%',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    margin: '0 auto',
    animation: 'scaleIn 0.5s ease-out',
    boxShadow: '0 10px 40px rgba(239, 68, 68, 0.3)',
  },
  cross: {
    width: '50px',
    height: '50px',
    animation: 'drawCross 0.5s ease-out 0.3s both',
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
  helpCard: {
    backgroundColor: 'rgba(255,255,255,0.15)',
    backdropFilter: 'blur(10px)',
    borderRadius: '16px',
    padding: '20px',
    marginBottom: '32px',
    textAlign: 'center',
    animation: 'fadeInUp 0.5s ease-out 0.4s both',
    border: '1px solid rgba(255,255,255,0.2)',
  },
  helpTitle: {
    color: 'white',
    fontSize: '18px',
    fontWeight: '600',
    marginBottom: '8px',
  },
  helpText: {
    color: 'rgba(255,255,255,0.9)',
    fontSize: '14px',
    marginBottom: '8px',
  },
  helpTextSmall: {
    color: 'rgba(255,255,255,0.6)',
    fontSize: '12px',
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
  buttonGroup: {
    display: 'flex',
    gap: '12px',
    justifyContent: 'center',
    animation: 'fadeInUp 0.5s ease-out 0.6s both',
  },
  buttonPrimary: {
    backgroundColor: 'white',
    color: '#f5576c',
    border: 'none',
    padding: '12px 28px',
    borderRadius: '50px',
    fontSize: '14px',
    fontWeight: '600',
    cursor: 'pointer',
    transition: 'all 0.3s ease',
    boxShadow: '0 4px 15px rgba(0,0,0,0.1)',
  },
  buttonSecondary: {
    backgroundColor: 'transparent',
    color: 'white',
    border: '1px solid white',
    padding: '12px 28px',
    borderRadius: '50px',
    fontSize: '14px',
    fontWeight: '600',
    cursor: 'pointer',
    transition: 'all 0.3s ease',
  },
  decorativeCircle1: {
    position: 'absolute',
    top: '-100px',
    left: '-100px',
    width: '300px',
    height: '300px',
    borderRadius: '50%',
    background: 'radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 70%)',
    zIndex: 1,
  },
  decorativeCircle2: {
    position: 'absolute',
    bottom: '-100px',
    right: '-100px',
    width: '250px',
    height: '250px',
    borderRadius: '50%',
    background: 'radial-gradient(circle, rgba(255,255,255,0.08) 0%, transparent 70%)',
    zIndex: 1,
  },
};