package ci.agnebytiassa.tourisme;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.view.animation.AlphaAnimation;
import android.view.animation.Animation;
import android.view.animation.ScaleAnimation;

public class SplashActivity extends Activity {

    private static final long SPLASH_DURATION_MS = 1800L;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_splash);

        View card = findViewById(R.id.splashCard);
        View logo = findViewById(R.id.splashLogo);
        View title = findViewById(R.id.splashTitle);
        View tagline = findViewById(R.id.splashTagline);

        ScaleAnimation scale = new ScaleAnimation(
                0.90f, 1.0f, 0.90f, 1.0f,
                Animation.RELATIVE_TO_SELF, 0.5f,
                Animation.RELATIVE_TO_SELF, 0.5f
        );
        scale.setDuration(650L);
        scale.setFillAfter(true);
        card.startAnimation(scale);

        AlphaAnimation logoFade = new AlphaAnimation(0.15f, 1.0f);
        logoFade.setDuration(700L);
        logo.startAnimation(logoFade);

        AlphaAnimation textFade = new AlphaAnimation(0.0f, 1.0f);
        textFade.setStartOffset(280L);
        textFade.setDuration(650L);
        title.startAnimation(textFade);
        tagline.startAnimation(textFade);

        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            startActivity(new Intent(SplashActivity.this, MainActivity.class));
            overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
            finish();
        }, SPLASH_DURATION_MS);
    }
}
